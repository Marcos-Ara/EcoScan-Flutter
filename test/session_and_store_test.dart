import 'package:ecoscan_mobile/models/detection_record.dart';
import 'package:ecoscan_mobile/state/ecoscan_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('histórico e foto separados por conta', () async {
    final store = await EcoScanStore.load();
    store.switchUser('ana');
    await store.setProfilePhoto('photo-a.jpg');
    await store.addDetection(
      DetectionRecord(
        id: '1',
        name: 'Plástico',
        category: 'Plástico',
        bin: 'Vermelha',
        destination: 'Reciclagem',
        confidence: .9,
        imagePath: '',
        detectedAt: DateTime(2026, 9, 16),
      ),
    );
    store.switchUser('bia');
    expect(store.detections, isEmpty);
    expect(store.profilePhoto, isEmpty);
    store.switchUser('ana');
    expect(store.scanCount, 1);
    expect(store.profilePhoto, 'photo-a.jpg');
    store.switchUser(null);
    expect(store.detections, isEmpty);
    store.dispose();
  });
}
