import 'dart:convert';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'waste_classifier.dart';

/// Runs the browser-side TensorFlow.js models declared in web/index.html.
/// The JS bridge returns plain objects so no Flutter plugin / MethodChannel is
/// needed on Web. The models are cached by JavaScript after the first scan.
Future<List<LabelCandidate>> classifyWebImage(Uint8List bytes) async {
  if (bytes.isEmpty) return const <LabelCandidate>[];
  final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  final promise = js_util.callMethod<Object?>(
    js_util.globalThis,
    'ecoscanClassifyImage',
    <Object?>[dataUrl],
  );
  if (promise == null) {
    throw StateError('Classificador Web não foi carregado.');
  }
  final raw = await js_util.promiseToFuture<Object?>(promise);
  final converted = js_util.dartify(raw);
  if (converted is! List) return const <LabelCandidate>[];

  final labels = <LabelCandidate>[];
  for (final item in converted) {
    if (item is! Map) continue;
    final label = item['label']?.toString().trim() ?? '';
    final rawConfidence = item['confidence'];
    final confidence = rawConfidence is num
        ? rawConfidence.toDouble()
        : double.tryParse(rawConfidence?.toString() ?? '') ?? 0;
    if (label.isNotEmpty && confidence.isFinite) {
      labels.add(LabelCandidate(label, confidence.clamp(0, 1).toDouble()));
    }
  }
  labels.sort((a, b) => b.confidence.compareTo(a.confidence));
  return labels;
}
