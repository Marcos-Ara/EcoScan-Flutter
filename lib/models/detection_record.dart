class DetectionRecord {
  const DetectionRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.bin,
    required this.destination,
    required this.confidence,
    required this.imagePath,
    required this.detectedAt,
  });

  final String id;
  final String name;
  final String category;
  final String bin;
  final String destination;
  final double confidence;
  final String imagePath;
  final DateTime detectedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'bin': bin,
    'destination': destination,
    'confidence': confidence,
    'imagePath': imagePath,
    'detectedAt': detectedAt.toIso8601String(),
  };

  factory DetectionRecord.fromJson(Map<String, dynamic> json) {
    return DetectionRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Objeto analisado',
      category: json['category']?.toString() ?? 'Verificar material',
      bin: json['bin']?.toString() ?? 'Consulte a coleta local',
      destination:
          json['destination']?.toString() ?? 'Verifique antes de descartar',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      imagePath: json['imagePath']?.toString() ?? '',
      detectedAt:
          DateTime.tryParse(json['detectedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
