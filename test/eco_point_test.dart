import 'package:ecoscan_mobile/models/eco_point.dart';
import 'package:ecoscan_mobile/state/eco_point_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('calcula e preserva a distância de um EcoPonto', () {
    const point = EcoPoint(
      id: '1',
      name: 'Teste',
      type: 'Reciclagem',
      category: EcoPointCategory.recycling,
      latitude: -23.5505,
      longitude: -46.6333,
    );

    final nearby = point.withDistanceFrom(const LatLng(-23.5510, -46.6333));

    expect(nearby.distanceMeters, isNotNull);
    expect(nearby.distanceMeters!, greaterThan(50));
    expect(nearby.distanceMeters!, lessThan(60));
  });

  test('limita a área automática de busca', () {
    expect(EcoPointController.radiusForZoom(15), 2500);
    expect(EcoPointController.radiusForZoom(3), 25000);
  });
}
