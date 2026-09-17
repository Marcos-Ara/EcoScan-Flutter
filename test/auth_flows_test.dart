import 'dart:convert';

import 'package:ecoscan_mobile/services/firebase_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  final tokens = {
    'idToken': 'id',
    'refreshToken': 'refresh',
    'expiresIn': '3600',
  };
  Map<String, dynamic> user(bool verified) => {
    'users': [
      {
        'localId': 'ana',
        'email': 'ana@example.com',
        'displayName': 'Ana',
        'emailVerified': verified,
      },
    ],
  };
  test(
    'cadastro cria perfil e envia confirmação sem liberar conta não verificada',
    () async {
      final actions = <String>[];
      final auth = FirebaseSession(
        client: MockClient((request) async {
          final action = request.url.path.split(':').last;
          actions.add(action);
          final body = jsonDecode(request.body) as Map;
          if (action == 'signUp') return http.Response(jsonEncode(tokens), 200);
          if (action == 'update') expect(body['displayName'], 'Ana');
          if (action == 'sendOobCode') {
            expect(body['requestType'], 'VERIFY_EMAIL');
          }
          return http.Response(
            jsonEncode(action == 'lookup' ? user(false) : {}),
            200,
          );
        }),
      );
      await auth.register(' Ana ', 'ana@example.com', 'password');
      expect(actions, ['signUp', 'update', 'lookup', 'sendOobCode']);
      expect(auth.account?.verified, isFalse);
      auth.dispose();
    },
  );
  test('recuperação de senha solicita link sem criar sessão', () async {
    final auth = FirebaseSession(
      client: MockClient((request) async {
        expect(jsonDecode(request.body), {
          'requestType': 'PASSWORD_RESET',
          'email': 'ana@example.com',
        });
        return http.Response('{}', 200);
      }),
    );
    await auth.resetPassword(' ana@example.com ');
    expect(auth.account, isNull);
    auth.dispose();
  });
  test('alterar e-mail exige verificar o novo endereço', () async {
    var requested = false;
    final auth = FirebaseSession(
      client: MockClient((request) async {
        if (request.url.path.endsWith('signInWithPassword')) {
          return http.Response(jsonEncode(tokens), 200);
        }
        if (request.url.path.endsWith('sendOobCode')) {
          final body = jsonDecode(request.body) as Map;
          expect(body['requestType'], 'VERIFY_AND_CHANGE_EMAIL');
          expect(body['newEmail'], 'novo@example.com');
          requested = true;
        }
        return http.Response(
          jsonEncode(request.url.path.endsWith('lookup') ? user(true) : {}),
          200,
        );
      }),
    );
    await auth.signIn('ana@example.com', 'password');
    await auth.updateProfile('Ana', 'novo@example.com');
    expect(requested, isTrue);
    expect(auth.account?.email, 'ana@example.com');
    auth.dispose();
  });
  test('alterar senha exige autenticar novamente antes de atualizar', () async {
    var logins = 0;
    final auth = FirebaseSession(
      client: MockClient((request) async {
        if (request.url.path.endsWith('signInWithPassword')) {
          logins++;
          return http.Response(jsonEncode(tokens), 200);
        }
        if (request.url.path.endsWith('update')) {
          expect(jsonDecode(request.body)['password'], 'new-password');
          expect(logins, 2);
          return http.Response(jsonEncode(tokens), 200);
        }
        return http.Response(jsonEncode(user(true)), 200);
      }),
    );
    await auth.signIn('ana@example.com', 'password');
    await auth.changePassword('password', 'new-password');
    auth.dispose();
  });
  test('falha de conexão ao restaurar não entra no aplicativo', () async {
    FlutterSecureStorage.setMockInitialValues({
      'ecoscan.firebase.refresh.v2': 'refresh',
    });
    final auth = FirebaseSession(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await auth.restore();
    expect(auth.account, isNull);
    expect(auth.restoreError, isNotNull);
    expect(auth.restoring, isFalse);
    auth.dispose();
  });
  test('sessão começa sem conta autenticada', () async {
    final auth = FirebaseSession();
    expect(auth.account, isNull);
    expect(auth.restoring, isTrue);
    auth.dispose();
  });
}
