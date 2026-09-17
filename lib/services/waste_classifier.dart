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
    this.detectedObject,
  });

  final MaterialGuide? material;
  final double confidence;
  final List<MaterialGuide> options;
  final String source;
  final String? instruction;
  final String? detectedObject;

  bool get isKnown => material != null;
  bool get isManual => source == 'manual';
  bool get isAutomatic => isKnown && !isManual;

  String get name => material?.name ?? 'Material não identificado';
  String get category => name;
  String get bin => material?.bin ?? '—';
  String get destination =>
      instruction ??
      material?.instruction ??
      'A IA não conseguiu identificar o material com segurança. Tire outra foto aproximando apenas um objeto e usando boa iluminação.';

  WasteClassification confirmed(MaterialGuide choice) => WasteClassification(
        material: choice,
        source: 'manual',
        detectedObject: detectedObject,
      );

  WasteClassification copyWith({
    MaterialGuide? material,
    double? confidence,
    List<MaterialGuide>? options,
    String? source,
    String? instruction,
    String? detectedObject,
  }) =>
      WasteClassification(
        material: material ?? this.material,
        confidence: confidence ?? this.confidence,
        options: options ?? this.options,
        source: source ?? this.source,
        instruction: instruction ?? this.instruction,
        detectedObject: detectedObject ?? this.detectedObject,
      );
}

/// Mapeia rótulos de visão computacional para o fluxo do EcoScan.
///
/// A IA identifica o objeto primeiro e depois resolve automaticamente o material
/// quando existe evidência suficiente. O aplicativo nunca obriga o usuário a
/// escolher manualmente o material: em caso de baixa confiança ele pede uma nova
/// foto, evitando registrar um descarte incorreto como se fosse certeza.
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
      'cellular telephone',
      'smartphone',
      'computer',
      'desktop computer',
      'laptop',
      'notebook computer',
      'keyboard',
      'computer keyboard',
      'computer mouse',
      'mouse computer',
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
      'water bottle',
      'pop bottle',
      'soda bottle',
      'shampoo bottle',
      'lotion bottle',
      'detergent bottle',
      'pill bottle',
      'plastic bag',
      'polyethylene',
      'pet bottle',
      'plastic container',
    ],
    'paper': [
      'paper',
      'cardboard',
      'paperboard',
      'newspaper',
      'cardboard box',
      'carton',
      'envelope',
      'book',
      'notebook',
      'paper bag',
    ],
    'glass': [
      'glass',
      'glass bottle',
      'glass jar',
      'glass container',
      'beer bottle',
      'wine bottle',
      'perfume bottle',
      'mason jar',
      'wine glass',
    ],
    'metal': [
      'aluminum',
      'aluminium',
      'tin can',
      'can',
      'beer can',
      'beverage can',
      'aluminum can',
      'steel',
      'metal bottle',
      'metal container',
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
      'pear',
      'pineapple',
      'strawberry',
    ],
  };

  static const _specificMaterialLabels = <String>{
    'beer bottle',
    'wine bottle',
    'water bottle',
    'pop bottle',
    'soda bottle',
    'plastic bottle',
    'shampoo bottle',
    'lotion bottle',
    'detergent bottle',
    'pill bottle',
    'glass bottle',
    'glass jar',
    'mason jar',
    'beer can',
    'tin can',
    'aluminum can',
    'beverage can',
    'cellular telephone',
    'notebook computer',
    'computer mouse',
  };

  static const _objectNames = <String, String>{
    'bottle': 'Garrafa',
    'beer bottle': 'Garrafa de vidro',
    'wine bottle': 'Garrafa de vidro',
    'glass bottle': 'Garrafa de vidro',
    'water bottle': 'Garrafa plástica',
    'pop bottle': 'Garrafa plástica',
    'soda bottle': 'Garrafa plástica',
    'plastic bottle': 'Garrafa plástica',
    'shampoo bottle': 'Frasco de shampoo',
    'lotion bottle': 'Frasco plástico',
    'detergent bottle': 'Frasco de detergente',
    'jar': 'Pote',
    'glass jar': 'Pote de vidro',
    'mason jar': 'Pote de vidro',
    'cup': 'Copo',
    'wine glass': 'Taça de vidro',
    'can': 'Lata',
    'tin can': 'Lata metálica',
    'beer can': 'Lata metálica',
    'aluminum can': 'Lata de alumínio',
    'beverage can': 'Lata metálica',
    'cardboard box': 'Caixa de papelão',
    'box': 'Caixa',
    'paper': 'Papel',
    'book': 'Livro',
    'newspaper': 'Jornal',
    'banana': 'Banana',
    'apple': 'Maçã',
    'orange': 'Laranja',
    'broccoli': 'Brócolis',
    'carrot': 'Cenoura',
    'mobile phone': 'Celular',
    'cell phone': 'Celular',
    'cellular telephone': 'Celular',
    'smartphone': 'Celular',
    'laptop': 'Notebook',
    'notebook computer': 'Notebook',
    'keyboard': 'Teclado',
    'computer keyboard': 'Teclado',
    'computer mouse': 'Mouse',
    'remote control': 'Controle remoto',
    'television': 'Televisão',
    'battery': 'Bateria/Pilha',
    'light bulb': 'Lâmpada',
  };

  static WasteClassification classifyCandidates(
    List<LabelCandidate> candidates,
  ) {
    final evidence = <String, double>{};
    for (final candidate in candidates) {
      if (!candidate.confidence.isFinite) continue;
      final label = normalize(candidate.label);
      final specific = _specificMaterialLabels.contains(label);
      final minimum = specific ? 0.22 : 0.55;
      if (candidate.confidence < minimum) continue;
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
      if ((evidence[special] ?? 0) >= 0.65) {
        return WasteClassification(
          material: MaterialGuide.byId(special),
          confidence: evidence[special]!,
          detectedObject: bestObjectName(candidates),
        );
      }
    }

    final ordered = evidence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isNotEmpty) {
      if (ordered.length > 1 && ordered[0].value - ordered[1].value < 0.12) {
        return WasteClassification(
          options: ordered.map((e) => MaterialGuide.byId(e.key)).toList(),
          detectedObject: bestObjectName(candidates),
        );
      }
      return WasteClassification(
        material: MaterialGuide.byId(ordered.first.key),
        confidence: ordered.first.value,
        detectedObject: bestObjectName(candidates),
      );
    }

    return WasteClassification(detectedObject: bestObjectName(candidates));
  }

  /// Finalização usada pelo Scanner. Remove a etapa de confirmação manual.
  /// Se o catálogo ficou ambíguo, tenta novamente com os rótulos específicos
  /// (inclusive rótulos de baixa confiança que são úteis para material).
  static WasteClassification finalizeAutomatic(
    WasteClassification result,
    List<LabelCandidate> candidates,
  ) {
    final objectName = result.detectedObject ?? bestObjectName(candidates);
    if (result.isKnown) {
      return result.copyWith(
        source: result.source == 'manual' ? 'ai' : result.source,
        detectedObject: objectName,
        options: const [],
      );
    }

    final weak = _weakSpecificMaterial(candidates);
    if (weak != null) {
      return WasteClassification(
        material: MaterialGuide.byId(weak.$1),
        confidence: weak.$2,
        source: 'ai-estimated',
        detectedObject: objectName,
      );
    }

    // Se só existe uma possibilidade real, a IA pode assumir essa opção.
    if (result.options.length == 1) {
      return WasteClassification(
        material: result.options.first,
        confidence: 0.55,
        source: 'ai-estimated',
        detectedObject: objectName,
      );
    }

    return WasteClassification(
      source: 'ai-unresolved',
      detectedObject: objectName,
      instruction:
          'Não consegui identificar o material com segurança. Tire outra foto aproximando apenas o objeto, com boa luz e fundo simples.',
    );
  }

  static (String, double)? _weakSpecificMaterial(
    List<LabelCandidate> candidates,
  ) {
    final sorted = [...candidates]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    for (final candidate in sorted) {
      if (!candidate.confidence.isFinite || candidate.confidence < 0.12) {
        continue;
      }
      final label = normalize(candidate.label);
      if (!_specificMaterialLabels.contains(label)) continue;
      for (final entry in directLabels.entries) {
        if (entry.value.contains(label)) {
          return (entry.key, candidate.confidence.clamp(0.35, 0.95).toDouble());
        }
      }
    }
    return null;
  }

  static String? bestObjectName(List<LabelCandidate> candidates) {
    final sorted = [...candidates]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    for (final candidate in sorted) {
      if (!candidate.confidence.isFinite || candidate.confidence < 0.12) {
        continue;
      }
      final label = normalize(candidate.label);
      final exact = _objectNames[label];
      if (exact != null) return exact;

      if (label.contains('bottle')) return 'Garrafa';
      if (label.contains('jar')) return 'Pote';
      if (label.contains('can')) return 'Lata';
      if (label.contains('phone')) return 'Celular';
      if (label.contains('computer')) return 'Computador';
      if (label.contains('cardboard')) return 'Papelão';
    }
    return null;
  }
}
