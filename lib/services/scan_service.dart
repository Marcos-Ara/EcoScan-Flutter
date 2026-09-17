import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'material_catalog.dart';
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
  Future<MaterialCatalog>? _catalog;
  bool _closed = false;

  bool get supportsAutomaticLabeling => !kIsWeb;

  ImageLabeler get _nativeLabeler => _labeler ??= ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  /// Backwards-compatible native/file API used by tests and older callers.
  Future<ScanResult> analyze(String sourcePath) => analyzeFile(XFile(sourcePath));

  Future<ScanResult> analyzeFile(XFile sourceFile) async {
    if (_closed) throw StateError('Scanner encerrado');

    final bytes = await sourceFile.readAsBytes();
    if (bytes.lengthInBytes > 30 * 1024 * 1024) {
      throw const FormatException('Escolha uma foto de até 30 MB.');
    }
    final prepared = await compute(_preparePhoto, bytes);

    if (kIsWeb) {
      WasteClassification result;
      try {
        final candidates = await classifyWebImage(prepared);
        try {
          final catalog = await (_catalog ??= MaterialCatalog.load());
          result = catalog.classify(candidates);
        } catch (_) {
          result = WasteClassifier.classifyCandidates(candidates);
        }
        if (!result.isKnown && result.options.isEmpty) {
          result = const WasteClassification(
            instruction:
                'A IA não reconheceu o material com segurança. Aproxime o objeto, use boa luz ou confirme o material abaixo.',
            source: 'web-ai',
          );
        }
      } catch (_) {
        result = const WasteClassification(
          instruction:
              'O classificador Web não ficou disponível. Confira a internet e tente novamente; você também pode confirmar o material abaixo.',
          source: 'web-ai',
        );
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
      final labels = await _nativeLabeler.processImage(
        InputImage.fromFilePath(file.path),
      );
      final candidates = labels
          .map((label) => LabelCandidate(label.label, label.confidence))
          .toList(growable: false);
      WasteClassification result;
      try {
        final catalog = await (_catalog ??= MaterialCatalog.load());
        result = catalog.classify(candidates);
      } catch (_) {
        result = WasteClassifier.classifyCandidates(candidates);
      }
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

  /// Creates a small local thumbnail that is safe to persist in browser
  /// SharedPreferences/localStorage. Native builds continue storing real files.
  Future<String> historyDataUrl(Uint8List bytes) async {
    final thumbnail = await compute(_prepareHistoryPhoto, bytes);
    return 'data:image/jpeg;base64,${base64Encode(thumbnail)}';
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final labeler = _labeler;
    _labeler = null;
    if (labeler != null) await labeler.close();
  }
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
