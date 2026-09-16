import 'package:ecoscan_mobile/services/waste_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WasteClassifier', () {
    test('classifica garrafa plástica', () {
      final result = WasteClassifier.classifyCandidates(const [
        LabelCandidate('Plastic bottle', 0.92),
      ]);

      expect(result.name, 'Garrafa plástica');
      expect(result.category, 'Plástico');
      expect(result.bin, 'Vermelha');
    });

    test('prioriza eletrônico reconhecido entre os melhores rótulos', () {
      final result = WasteClassifier.classifyCandidates(const [
        LabelCandidate('Object', 0.98),
        LabelCandidate('Mobile phone', 0.87),
      ]);

      expect(result.category, 'Eletrônico');
      expect(result.bin, 'Coleta especial');
    });

    test('orienta uma nova foto sem rótulos', () {
      final result = WasteClassifier.classifyCandidates(const []);

      expect(result.name, 'Objeto não identificado');
      expect(result.confidence, 0);
    });
  });
}
