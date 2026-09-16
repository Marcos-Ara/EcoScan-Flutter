import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../models/material_guide.dart';

class LabelCandidate {
  const LabelCandidate(this.label, this.confidence);
  final String label;
  final double confidence;
}

class WasteClassification {
  const WasteClassification({
    this.material,
    this.confidence = 0,
    this.options = const [],
    this.source = 'image',
    this.instruction,
  });
  final MaterialGuide? material;
  final double confidence;
  final List<MaterialGuide> options;
  final String source;
  final String? instruction;
  bool get isKnown => material != null;
  bool get isManual => source == 'manual';
  String get name => material?.name ?? 'Confirme o material';
  String get category => name;
  String get bin => material?.bin ?? 'Escolha o material abaixo';
  String get destination =>
      instruction ??
      material?.instruction ??
      'Não foi possível distinguir o material com segurança. Escolha abaixo ou tire outra foto.';
  WasteClassification confirmed(MaterialGuide choice) =>
      WasteClassification(material: choice, source: 'manual');
}

/// Full tokens/phrases, never substring matching ("can" != "candle").
/// Generic containers do not determine their material. Model scores describe
/// label recognition, not a calibrated probability of chemical composition.
abstract final class WasteClassifier {
  static WasteClassification fromMlLabels(List<ImageLabel> labels) =>
      classifyCandidates(
        labels.map((l) => LabelCandidate(l.label, l.confidence)).toList(),
      );
  static const unknown = WasteClassification();
  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static const directLabels = <String, List<String>>{
    'electronic': [
      'mobile phone',
      'cell phone',
      'smartphone',
      'computer',
      'laptop',
      'keyboard',
      'computer keyboard',
      'computer mouse',
      'headphones',
      'headphone',
      'earphones',
      'earbud',
      'charger',
      'remote control',
      'television',
      'tablet computer',
    ],
    'special': [
      'battery',
      'light bulb',
      'fluorescent lamp',
      'medicine',
      'syringe',
    ],
    'plastic': [
      'plastic',
      'plastic bottle',
      'plastic bag',
      'polyethylene',
      'pet bottle',
    ],
    'paper': ['paper', 'cardboard', 'paperboard', 'newspaper', 'cardboard box'],
    'glass': ['glass bottle', 'glass jar', 'glass container'],
    'metal': [
      'aluminum',
      'aluminium',
      'tin can',
      'beverage can',
      'aluminum can',
      'steel',
    ],
    'organic': [
      'food',
      'fruit',
      'vegetable',
      'banana',
      'apple',
      'orange',
      'broccoli',
      'carrot',
      'bread',
      'food waste',
      'banana peel',
      'vegetables',
      'lemon',
    ],
  };

  static WasteClassification classifyCandidates(
    List<LabelCandidate> candidates,
  ) {
    final evidence = <String, double>{};
    for (final candidate in candidates) {
      if (candidate.confidence < 0.60 || !candidate.confidence.isFinite) {
        continue;
      }
      final label = normalize(candidate.label);
      for (final entry in directLabels.entries) {
        if (entry.value.contains(label)) {
          final previous = evidence[entry.key] ?? 0;
          if (candidate.confidence > previous) {
            evidence[entry.key] = candidate.confidence;
          }
        }
      }
    }
    for (final special in ['special', 'electronic']) {
      if ((evidence[special] ?? 0) >= 0.7) {
        return WasteClassification(
          material: MaterialGuide.byId(special),
          confidence: evidence[special]!,
        );
      }
    }
    final ordered = evidence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isNotEmpty) {
      if (ordered.length > 1 && ordered[0].value - ordered[1].value < 0.15) {
        return WasteClassification(
          options: ordered.map((e) => MaterialGuide.byId(e.key)).toList(),
        );
      }
      return WasteClassification(
        material: MaterialGuide.byId(ordered.first.key),
        confidence: ordered.first.value,
      );
    }
    final labels = candidates
        .where((c) => c.confidence >= 0.6)
        .map((c) => normalize(c.label))
        .toSet();
    if (labels.any(
      const [
        'bottle',
        'jar',
        'glass',
        'cup',
        'container',
        'packaging',
      ].contains,
    )) {
      return WasteClassification(
        options: [
          'plastic',
          'glass',
          'metal',
          'paper',
        ].map(MaterialGuide.byId).toList(),
      );
    }
    return unknown;
  }
}
