import 'package:ecoscan_mobile/models/eco_point.dart';
import 'package:ecoscan_mobile/services/eco_point_service.dart';
import 'package:ecoscan_mobile/state/eco_point_controller.dart';
import 'package:ecoscan_mobile/state/ecoscan_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AreaService extends EcoPointService {
  final centers = <LatLng>[];
  @override
  Future<List<EcoPoint>> searchQuick(
    LatLng center,
    int radius, {
    List<String> queries = const ['ecoponto'],
  }) async {
    centers.add(center);
    return [
      EcoPoint(
        id: center.latitude.toString(),
        name: 'EcoPonto',
        type: 'Reciclagem',
        category: EcoPointCategory.recycling,
        latitude: center.latitude,
        longitude: center.longitude,
      ),
    ];
  }

  @override
  Future<List<EcoPoint>> searchDetailed(LatLng center, int radius) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'mudar a área mantém pontos anteriores e reordena pela nova referência',
    () async {
      final store = await EcoScanStore.load();
      final service = AreaService();
      final controller = EcoPointController(service: service, store: store);
      await controller.searchArea(const LatLng(-23.55, -46.63), zoom: 15);
      await controller.searchArea(const LatLng(-23.65, -46.73), zoom: 15);
      expect(controller.allPoints, hasLength(2));
      expect(controller.allPoints.first.latitude, -23.65);
      expect(controller.allPoints.last.distanceMeters, greaterThan(1000));
      expect(await store.loadCachedEcoPoints(), hasLength(2));
      controller.dispose();
      service.dispose();
      store.dispose();
    },
  );

  test('mover o mapa não dispara busca automática de rede', () async {
    final store = await EcoScanStore.load();
    final service = AreaService();
    final controller = EcoPointController(service: service, store: store);
    controller.onMapMoved(const LatLng(-23.60, -46.70), 15);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    expect(service.centers, isEmpty);
    expect(controller.status, contains('atualizar'));
    controller.dispose();
    service.dispose();
    store.dispose();
  });
  test('atualizar usa a última área e não duplica marcadores', () async {
    final store = await EcoScanStore.load();
    final service = AreaService();
    final controller = EcoPointController(service: service, store: store);
    await controller.searchArea(const LatLng(-22, -43), zoom: 14);
    await controller.refreshVisibleArea();
    expect(service.centers.last, const LatLng(-22, -43));
    expect(controller.totalCount, 1);
    controller.dispose();
    service.dispose();
    store.dispose();
  });
}
