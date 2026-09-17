import 'package:ecoscan_mobile/services/waste_classifier.dart';
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
  test('baixa confiança não inventa material e pede nova foto', () {
    final raw = WasteClassifier.classifyCandidates(const [
      LabelCandidate('plastic', .3),
    ]);
    final result = WasteClassifier.finalizeAutomatic(
      raw,
      const [LabelCandidate('plastic', .3)],
    );
    expect(result.isKnown, isFalse);
    expect(result.source, 'ai-unresolved');
    expect(result.destination, contains('Tire outra foto'));
  });
  test('evidências conflitantes não exibem confirmação manual', () {
    final candidates = const [
      LabelCandidate('plastic', .85),
      LabelCandidate('glass bottle', .87),
    ];
    final raw = WasteClassifier.classifyCandidates(candidates);
    final result = WasteClassifier.finalizeAutomatic(raw, candidates);
    expect(result.isManual, isFalse);
    expect(result.source, isNot('manual'));
  });
  test('rótulo específico fraco ainda pode virar estimativa automática', () {
    const candidates = [LabelCandidate('glass bottle', .18)];
    final raw = WasteClassifier.classifyCandidates(candidates);
    final result = WasteClassifier.finalizeAutomatic(raw, candidates);
    expect(result.isKnown, isTrue);
    expect(result.name, 'Vidro');
    expect(result.bin, 'Verde');
    expect(result.isManual, isFalse);
  });
}
