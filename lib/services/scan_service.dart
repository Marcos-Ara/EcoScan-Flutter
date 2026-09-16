import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'material_catalog.dart';
import 'waste_classifier.dart';

class ScanResult {
  const ScanResult(this.imagePath, this.classification);
  final String imagePath;
  final WasteClassification classification;
}

/// A single model instance, and the same pipeline for camera and gallery.
class ScanService {
  final _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );
  Future<MaterialCatalog>? _catalog;
  bool _closed = false;

  Future<ScanResult> analyze(String sourcePath) async {
    if (_closed) throw StateError('Scanner encerrado');
    final source = File(sourcePath);
    if (await source.length() > 30 * 1024 * 1024) {
      throw const FormatException('Escolha uma foto de até 30 MB.');
    }
    final bytes = await source.readAsBytes();
    final prepared = await compute(_preparePhoto, bytes);
    final temp = await getTemporaryDirectory();
    final file = File(
      p.join(
        temp.path,
        'ecoscan_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(prepared, flush: true);
    try {
      final labels = await _labeler.processImage(
        InputImage.fromFilePath(file.path),
      );
      final candidates = labels
          .map((l) => LabelCandidate(l.label, l.confidence))
          .toList();
      WasteClassification result;
      try {
        final catalog = await (_catalog ??= MaterialCatalog.load());
        result = catalog.classify(candidates);
      } catch (_) {
        result = WasteClassifier.classifyCandidates(candidates);
      }
      return ScanResult(file.path, result);
    } catch (_) {
      await file.delete();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _labeler.close();
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
