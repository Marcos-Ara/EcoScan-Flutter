import 'package:latlong2/latlong.dart';

enum EcoPointCategory { recycling, disposal }

class EcoPoint {
  const EcoPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String type;
  final EcoPointCategory category;
  final double latitude;
  final double longitude;
  final double? distanceMeters;

  LatLng get position => LatLng(latitude, longitude);
  String get coordinateKey =>
      '${latitude.toStringAsFixed(5)}|${longitude.toStringAsFixed(5)}';

  EcoPoint withDistanceFrom(LatLng origin) {
    final distance = const Distance().as(LengthUnit.Meter, origin, position);
    return copyWith(distanceMeters: distance);
  }

  EcoPoint copyWith({double? distanceMeters}) {
    return EcoPoint(
      id: id,
      name: name,
      type: type,
      category: category,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'category': category.name,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMeters': distanceMeters,
  };

  factory EcoPoint.fromJson(Map<String, dynamic> json) {
    return EcoPoint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'EcoPonto',
      type: json['type']?.toString() ?? 'Ponto de descarte',
      category: json['category'] == EcoPointCategory.disposal.name
          ? EcoPointCategory.disposal
          : EcoPointCategory.recycling,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}
