import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class LabelCandidate {
  const LabelCandidate(this.label, this.confidence);

  final String label;
  final double confidence;
}

class WasteClassification {
  const WasteClassification({
    required this.name,
    required this.category,
    required this.bin,
    required this.destination,
    required this.confidence,
  });

  final String name;
  final String category;
  final String bin;
  final String destination;
  final double confidence;
}

abstract final class WasteClassifier {
  static WasteClassification fromMlLabels(List<ImageLabel> labels) {
    return classifyCandidates(
      labels
          .map((label) => LabelCandidate(label.label, label.confidence))
          .toList(),
    );
  }

  static WasteClassification classifyCandidates(
    List<LabelCandidate> candidates,
  ) {
    if (candidates.isEmpty) return unknown;
    final ordered = [...candidates]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    for (final candidate in ordered) {
      final value = candidate.label.toLowerCase();
      if (_containsAny(value, const [
        'battery',
        'phone',
        'mobile',
        'computer',
        'keyboard',
        'electronic',
        'device',
        'cable',
        'charger',
      ])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Eletrônico',
          bin: 'Coleta especial',
          destination: 'Leve a um ponto de coleta de eletrônicos ou EcoPonto autorizado.',
          confidence: candidate.confidence,
        );
      }
      if (_containsAny(value, const [
        'paper',
        'cardboard',
        'newspaper',
        'book',
        'carton',
      ])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Papel',
          bin: 'Azul',
          destination: 'Mantenha seco e limpo antes de enviar para reciclagem.',
          confidence: candidate.confidence,
        );
      }
      if (_containsAny(value, const ['glass', 'jar'])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Vidro',
          bin: 'Verde',
          destination: 'Embale com segurança e leve para a coleta de vidro.',
          confidence: candidate.confidence,
        );
      }
      if (_containsAny(value, const [
        'metal',
        'aluminum',
        'steel',
        'tin',
        'can',
      ])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Metal',
          bin: 'Amarela',
          destination: 'Esvazie e encaminhe para reciclagem de metais.',
          confidence: candidate.confidence,
        );
      }
      if (_containsAny(value, const [
        'plastic',
        'bottle',
        'container',
        'packaging',
        'cup',
        'toy',
      ])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Plástico',
          bin: 'Vermelha',
          destination: 'Lave rapidamente, seque e descarte com os recicláveis.',
          confidence: candidate.confidence,
        );
      }
      if (_containsAny(value, const [
        'food',
        'fruit',
        'vegetable',
        'banana',
        'apple',
        'plant',
        'leaf',
        'bread',
        'meal',
      ])) {
        return WasteClassification(
          name: _friendlyName(candidate.label),
          category: 'Orgânico',
          bin: 'Marrom',
          destination:
              'Use a coleta orgânica ou compostagem, quando disponível.',
          confidence: candidate.confidence,
        );
      }
    }

    final best = ordered.first;
    return WasteClassification(
      name: _friendlyName(best.label),
      category: 'Verificar material',
      bin: 'Consulte a coleta local',
      destination:
          'A IA reconheceu o objeto, mas o material precisa ser confirmado.',
      confidence: best.confidence,
    );
  }

  static const unknown = WasteClassification(
    name: 'Objeto não identificado',
    category: 'Verificar material',
    bin: 'Consulte a coleta local',
    destination: 'Tire outra foto com boa luz e o objeto centralizado.',
    confidence: 0,
  );

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  static String _friendlyName(String label) {
    const translations = {
      'bottle': 'Garrafa',
      'plastic bottle': 'Garrafa plástica',
      'can': 'Lata',
      'paper': 'Papel',
      'cardboard': 'Papelão',
      'glass': 'Vidro',
      'mobile phone': 'Celular',
      'computer': 'Computador',
      'battery': 'Bateria',
      'food': 'Alimento',
    };
    final normalized = label.trim().toLowerCase();
    if (translations.containsKey(normalized)) return translations[normalized]!;
    if (label.trim().isEmpty) return 'Objeto analisado';
    final clean = label.trim();
    return '${clean[0].toUpperCase()}${clean.substring(1)}';
  }
}
