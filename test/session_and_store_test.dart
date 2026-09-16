import 'dart:convert';

import 'package:ecoscan_mobile/models/detection_record.dart';
import 'package:ecoscan_mobile/services/firebase_session.dart';
import 'package:ecoscan_mobile/state/ecoscan_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('login não confirma um e-mail não verificado', () async {
    final paths = <String>[];
    final auth = FirebaseSession(
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('signInWithPassword')) {
          return http.Response(
            jsonEncode({
              'idToken': 'test-id',
              'refreshToken': 'test-refresh',
              'expiresIn': '3600',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'users': [
              {
                'localId': 'a',
                'email': 'test@example.com',
                'displayName': 'Ana',
                'emailVerified': false,
              },
            ],
          }),
          200,
        );
      }),
    );
    await auth.signIn('test@example.com', 'password');
    expect(auth.account!.verified, isFalse);
    expect(paths, ['/v1/accounts:signInWithPassword', '/v1/accounts:lookup']);
    expect(
      await const FlutterSecureStorage().read(
        key: 'ecoscan.firebase.refresh.v2',
      ),
      'test-refresh',
    );
    await auth.signOut();
    expect(auth.account, isNull);
    expect(
      await const FlutterSecureStorage().read(
        key: 'ecoscan.firebase.refresh.v2',
      ),
      isNull,
    );
    auth.dispose();
  });
  test('senha inválida não cria sessão', () async {
    final auth = FirebaseSession(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'INVALID_LOGIN_CREDENTIALS'},
          }),
          400,
        ),
      ),
    );
    await expectLater(
      auth.signIn('test@example.com', 'bad'),
      throwsA(isA<AuthFailure>()),
    );
    expect(auth.account, isNull);
    auth.dispose();
  });
  test('sessão recuperada renova o token e verifica a conta', () async {
    FlutterSecureStorage.setMockInitialValues({
      'ecoscan.firebase.refresh.v2': 'old-refresh',
    });
    final auth = FirebaseSession(
      client: MockClient((request) async {
        if (request.url.host == 'securetoken.googleapis.com') {
          expect(request.body, contains('refresh_token=old-refresh'));
          return http.Response(
            jsonEncode({
              'id_token': 'new-id',
              'refresh_token': 'new-refresh',
              'expires_in': '3600',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'users': [
              {'localId': 'a', 'emailVerified': true},
            ],
          }),
          200,
        );
      }),
    );
    await auth.restore();
    expect(auth.account?.uid, 'a');
    expect(auth.account?.verified, isTrue);
    expect(auth.restoring, isFalse);
    auth.dispose();
  });
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
