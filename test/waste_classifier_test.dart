import 'package:ecoscan_mobile/services/waste_classifier.dart';
import 'package:ecoscan_mobile/models/material_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('somente material no título', () {
    final result = WasteClassifier.classifyCandidates(const [
      LabelCandidate('plastic bottle', .94),
    ]);
    expect(result.name, 'Plástico');
    expect(result.bin, 'Vermelha');
  });
  test('não confunde trechos de palavras', () {
    for (final word in [
      'candle',
      'candy',
      'tinny',
      'plantation',
      'mobile home',
      'glasses',
    ]) {
      expect(
        WasteClassifier.classifyCandidates([LabelCandidate(word, .99)]).isKnown,
        isFalse,
        reason: word,
      );
    }
  });
  test('baixa confiança pede confirmação', () {
    expect(
      WasteClassifier.classifyCandidates(const [LabelCandidate('plastic', .3)])
          .isKnown,
      isFalse,
    );
  });
  test('evidências conflitantes pedem confirmação', () {
    final result = WasteClassifier.classifyCandidates(const [
      LabelCandidate('plastic', .85),
      LabelCandidate('glass bottle', .87),
    ]);
    expect(result.isKnown, isFalse);
  });
  test('confirmação manual não inventa confiança', () {
    final result = WasteClassifier.unknown.confirmed(
      MaterialGuide.byId('plastic'),
    );
    expect(result.isManual, isTrue);
    expect(result.confidence, 0);
    expect(result.bin, 'Vermelha');
  });
}
