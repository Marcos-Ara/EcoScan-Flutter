import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as od;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'material_catalog.dart';
import 'supabase_material_resolver.dart';
import 'waste_classifier.dart';
import 'web_image_labeler.dart';

class ScanResult {
  const ScanResult({
    required this.imagePath,
    required this.imageBytes,
    required this.classification,
  });

  final String imagePath;
  final Uint8List imageBytes;
  final WasteClassification classification;
}

/// Image analysis pipeline shared by camera and gallery.
///
/// ML Kit is used on Android/iOS. Web uses a browser-side TensorFlow.js
/// classifier (COCO-SSD + MobileNet) through a tiny JS bridge, so camera and
/// gallery scans work without an API key and without native MethodChannels.
class ScanService {
  ImageLabeler? _labeler;
  od.ObjectDetector? _objectDetector;
  Future<MaterialCatalog>? _catalog;
  final SupabaseMaterialResolver _supabaseResolver = SupabaseMaterialResolver();
  bool _closed = false;

  bool get supportsAutomaticLabeling => true;

  ImageLabeler get _nativeLabeler => _labeler ??= ImageLabeler(
    // Keep moderate labels; WasteClassifier applies stricter per-label floors.
    options: ImageLabelerOptions(confidenceThreshold: 0.20),
  );

  od.ObjectDetector get _nativeObjectDetector => _objectDetector ??=
      od.ObjectDetector(
        options: od.ObjectDetectorOptions(
          mode: od.DetectionMode.single,
          classifyObjects: false,
          // The scanner asks the user to frame one item, so detecting only the
          // most prominent object avoids background labels contaminating the
          // material classification.
          multipleObjects: false,
        ),
      );

  /// Backwards-compatible native/file API used by tests and older callers.
  Future<ScanResult> analyze(String sourcePath) => analyzeFile(XFile(sourcePath));

  Future<void> warmup() async {
    _catalog ??= MaterialCatalog.load();
    if (kIsWeb) await warmupWebScanner();
  }

  Future<WasteClassification> _resolveCandidates(
    List<LabelCandidate> candidates, {
    required bool live,
  }) async {
    // Resolve locally first. The bundled catalog is instant and avoids making a
    // network round-trip for every photo. Supabase is used only to enrich or
    // resolve labels that the local snapshot could not decide.
    WasteClassification result;
    try {
      final catalog = await (_catalog ??= MaterialCatalog.load());
      result = catalog.classify(candidates);
    } catch (_) {
      result = WasteClassifier.classifyCandidates(candidates);
    }

    if (!live && !result.isKnown) {
      final remote = await _supabaseResolver.resolve(candidates);
      if (remote != null) result = remote;
    }

    return WasteClassifier.finalizeAutomatic(result, candidates);
  }

  Future<ScanResult> analyzeFile(XFile sourceFile, {bool live = false, double brightness = 1}) async {
    if (_closed) throw StateError('Scanner encerrado');

    final bytes = await sourceFile.readAsBytes();
    if (bytes.lengthInBytes > 30 * 1024 * 1024) {
      throw const FormatException('Escolha uma foto de até 30 MB.');
    }
    // compute() runs on the UI thread on Web. Use native browser decoding
    // there instead of decoding/re-encoding every camera frame in Dart.
    final prepared = kIsWeb
        ? await prepareWebImage(bytes, maxSize: live ? 640 : 1280, brightness: brightness)
        : await compute(_preparePhoto, bytes);

    if (kIsWeb) {
      WasteClassification result;
      try {
        final candidates = await classifyWebImage(prepared, live: live);
        result = await _resolveCandidates(candidates, live: live);
      } catch (_) {
        throw const FormatException('A IA não respondeu. Confira a conexão e tente novamente. O primeiro uso baixa o modelo.');
      }
      return ScanResult(
        imagePath: sourceFile.path,
        imageBytes: prepared,
        classification: result,
      );
    }

    final temp = await getTemporaryDirectory();
    final file = File(
      p.join(
        temp.path,
        'ecoscan_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(prepared, flush: true);
    try {
      final candidates = await _nativeCandidates(file, prepared);
      final result = await _resolveCandidates(candidates, live: live);
      return ScanResult(
        imagePath: file.path,
        imageBytes: prepared,
        classification: result,
      );
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<LabelCandidate>> _nativeCandidates(
    File fullImage,
    Uint8List prepared,
  ) async {
    final merged = <String, LabelCandidate>{};

    void addLabels(Iterable<ImageLabel> labels) {
      for (final label in labels) {
        final candidate = LabelCandidate(label.label, label.confidence);
        final key = WasteClassifier.normalize(candidate.label);
        final previous = merged[key];
        if (previous == null || candidate.confidence > previous.confidence) {
          merged[key] = candidate;
        }
      }
    }

    // ML Kit's own guidance for object-centric classification is to locate the
    // object first and classify its crop. If object detection is unavailable on
    // a device for any reason, fall back to the full image instead of failing.
    File? cropFile;
    try {
      final objects = await _nativeObjectDetector.processImage(
        InputImage.fromFilePath(fullImage.path),
      );
      if (objects.isNotEmpty) {
        final crop = _cropDetectedObject(prepared, objects.first.boundingBox);
        if (crop != null) {
          final temp = await getTemporaryDirectory();
          cropFile = File(
            p.join(
              temp.path,
              'ecoscan_object_${DateTime.now().microsecondsSinceEpoch}.jpg',
            ),
          );
          await cropFile.writeAsBytes(crop, flush: true);
          final cropLabels = await _nativeLabeler.processImage(
            InputImage.fromFilePath(cropFile.path),
          );
          addLabels(cropLabels);
        }
      }
    } catch (_) {
      // Object detection is an accuracy enhancement, never a hard dependency.
    } finally {
      if (cropFile != null) {
        try {
          await cropFile.delete();
        } catch (_) {}
      }
    }

    final bestCropConfidence = merged.values.fold<double>(
      0,
      (best, value) => value.confidence > best ? value.confidence : best,
    );
    if (merged.isEmpty || bestCropConfidence < 0.40) {
      final fullLabels = await _nativeLabeler.processImage(
        InputImage.fromFilePath(fullImage.path),
      );
      addLabels(fullLabels);
    }

    final result = merged.values.toList(growable: false)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return result;
  }

  /// Creates a small local thumbnail that is safe to persist in browser
  /// SharedPreferences/localStorage. Native builds continue storing real files.
  Future<String> historyDataUrl(Uint8List bytes) async {
    final thumbnail = kIsWeb
        ? await prepareWebImage(bytes, maxSize: 480)
        : await compute(_prepareHistoryPhoto, bytes);
    return 'data:image/jpeg;base64,${base64Encode(thumbnail)}';
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final labeler = _labeler;
    final objectDetector = _objectDetector;
    _labeler = null;
    _objectDetector = null;
    if (labeler != null) await labeler.close();
    if (objectDetector != null) await objectDetector.close();
  }
}

Uint8List? _cropDetectedObject(Uint8List bytes, Rect rect) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final image = img.bakeOrientation(decoded);

  final left = rect.left;
  final top = rect.top;
  final width = rect.width;
  final height = rect.height;
  if (width <= 2 || height <= 2) return null;

  final padX = width * 0.14;
  final padY = height * 0.14;
  final x = (left - padX).floor().clamp(0, image.width - 1).toInt();
  final y = (top - padY).floor().clamp(0, image.height - 1).toInt();
  final right = (left + width + padX).ceil().clamp(x + 1, image.width).toInt();
  final bottom = (top + height + padY).ceil().clamp(y + 1, image.height).toInt();
  final cropped = img.copyCrop(
    image,
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
  return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
}

Uint8List _preparePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException(
      'Formato de foto não suportado. Escolha JPG ou PNG.',
    );
  }
  var image = img.bakeOrientation(decoded);
  if (image.width > 1440 || image.height > 1440) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: 1440,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: 1440,
            interpolation: img.Interpolation.average,
          );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

Uint8List _prepareHistoryPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var image = img.bakeOrientation(decoded);
  if (image.width > 640 || image.height > 640) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: 640,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: 640,
            interpolation: img.Interpolation.average,
          );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 76));
}
