import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../core/backend_config.dart';

class Account {
  const Account({
    required this.uid,
    required this.email,
    required this.name,
    required this.verified,
    this.photoUrl = '',
  });
  final String uid;
  final String email;
  final String name;
  final bool verified;
  final String photoUrl;
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    uid: json['localId'] as String,
    email: json['email'] as String? ?? '',
    name: json['displayName'] as String? ?? '',
    verified: json['emailVerified'] == true,
    photoUrl: json['photoUrl'] as String? ?? '',
  );
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
  @override
  String toString() => switch (code.split(' : ').first) {
    'INVALID_LOGIN_CREDENTIALS' ||
    'INVALID_PASSWORD' ||
    'EMAIL_NOT_FOUND' => 'E-mail ou senha incorretos.',
    'EMAIL_EXISTS' => 'Este e-mail já possui uma conta.',
    'INVALID_EMAIL' => 'Digite um e-mail válido.',
    'WEAK_PASSWORD' => 'Use uma senha com pelo menos 6 caracteres.',
    'TOO_MANY_ATTEMPTS_TRY_LATER' =>
      'Muitas tentativas. Aguarde e tente novamente.',
    'USER_DISABLED' => 'Esta conta está desativada.',
    'TOKEN_EXPIRED' ||
    'INVALID_ID_TOKEN' ||
    'INVALID_REFRESH_TOKEN' ||
    'USER_NOT_FOUND' => 'Sua sessão expirou. Entre novamente.',
    'CREDENTIAL_TOO_OLD_LOGIN_AGAIN' =>
      'Entre novamente para alterar este dado.',
    'OPERATION_NOT_ALLOWED' || 'PASSWORD_LOGIN_DISABLED' =>
      'Este método de acesso precisa ser habilitado no Firebase do projeto.',
    'NETWORK' =>
      'Sem conexão com o serviço. Confira a internet e tente novamente.',
    'GOOGLE_CONFIG' =>
      'O acesso com Google ainda precisa do ID OAuth Web deste projeto. Configure GOOGLE_WEB_CLIENT_ID e gere o app novamente.',
    'GOOGLE_UNSUPPORTED' =>
      'O acesso com Google não está disponível neste ambiente.',
    'CANCELED' => 'Acesso cancelado.',
    _ => 'Não foi possível concluir. Tente novamente.',
  };
}

/// Firebase Auth REST uses the same project and accounts as the web.
/// Refresh tokens are stored in Keychain/Keystore, never in preferences.
class FirebaseSession extends ChangeNotifier {
  FirebaseSession({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();
  final http.Client _client;
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'ecoscan.firebase.refresh.v2';
  String? _idToken;
  String? _refreshToken;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  Account? account;
  bool restoring = true;
  String? restoreError;
  Future<void>? _refreshing;
  bool _googleInitialized = false;
  Future<void>? _googleInitialization;
  bool googleReady = false;
  String? googleError;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;

  Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.https(
              'identitytoolkit.googleapis.com',
              '/v1/accounts:$action',
              {'key': BackendConfig.firebaseApiKey},
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Firebase-Locale': 'pt-BR',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('NETWORK');
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthFailure(
        (data['error'] as Map?)?['message']?.toString() ?? 'UNKNOWN',
      );
    }
    return data;
  }

  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    notifyListeners();
    try {
      _refreshToken = await _storage.read(key: _sessionKey);
      if (_refreshToken != null) {
        await _refresh();
        await reload();
      }
    } on AuthFailure catch (error) {
      if (error.code == 'NETWORK') {
        restoreError = error.toString();
      } else {
        await signOut();
      }
    } catch (_) {
      restoreError = 'Não foi possível recuperar o acesso. Tente novamente.';
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> _acceptTokens(Map<String, dynamic> data) async {
    _idToken = (data['idToken'] ?? data['id_token']) as String?;
    _refreshToken =
        (data['refreshToken'] ?? data['refresh_token']) as String? ??
        _refreshToken;
    final seconds =
        int.tryParse((data['expiresIn'] ?? data['expires_in']).toString()) ??
        3600;
    _expiresAt = DateTime.now().add(Duration(seconds: seconds));
    if (_refreshToken != null) {
      await _storage.write(key: _sessionKey, value: _refreshToken);
    }
  }

  Future<void> _refresh() =>
      _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  Future<void> _performRefresh() async {
    if (_refreshToken == null) throw const AuthFailure('TOKEN_EXPIRED');
    try {
      final response = await _client
          .post(
            Uri.https('securetoken.googleapis.com', '/v1/token', {
              'key': BackendConfig.firebaseApiKey,
            }),
            body: {
              'grant_type': 'refresh_token',
              'refresh_token': _refreshToken!,
            },
          )
          .timeout(const Duration(seconds: 15));
      await _acceptTokens(_decode(response));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('NETWORK');
    }
  }

  Future<String> get token async {
    if (_idToken == null ||
        DateTime.now().isAfter(
          _expiresAt.subtract(const Duration(minutes: 2)),
        )) {
      await _refresh();
    }
    return _idToken!;
  }

  Future<void> reload() async {
    final data = await _request('lookup', {'idToken': await token});
    final users = data['users'] as List?;
    if (users == null || users.isEmpty) {
      throw const AuthFailure('USER_NOT_FOUND');
    }
    account = Account.fromJson(Map<String, dynamic>.from(users.first as Map));
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final data = await _request('signInWithPassword', {
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    });
    await _acceptTokens(data);
    await reload();
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _request('signUp', {
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    });
    await _acceptTokens(data);
    await _request('update', {
      'idToken': await token,
      'displayName': name.trim(),
    });
    await reload();
    await sendVerification();
  }

  Future<void> sendVerification() async {
    await _request('sendOobCode', {
      'requestType': 'VERIFY_EMAIL',
      'idToken': await token,
    });
  }

  Future<void> resetPassword(String email) async {
    await _request('sendOobCode', {
      'requestType': 'PASSWORD_RESET',
      'email': email.trim(),
    });
  }

  Future<void> updateProfile(String name, String email) async {
    await _request('update', {
      'idToken': await token,
      'displayName': name.trim(),
    });
    if (email.trim() != account?.email) {
      await _request('sendOobCode', {
        'requestType': 'VERIFY_AND_CHANGE_EMAIL',
        'idToken': await token,
        'newEmail': email.trim(),
      });
    }
    await reload();
  }

  Future<void> changePassword(String current, String next) async {
    final email = account?.email;
    if (email == null) throw const AuthFailure('TOKEN_EXPIRED');
    await signIn(email, current);
    final data = await _request('update', {
      'idToken': await token,
      'password': next,
      'returnSecureToken': true,
    });
    await _acceptTokens(data);
    await reload();
  }

  Future<void> _ensureGoogleInitialized() =>
      _googleInitialization ??= _initializeGoogleSignIn();

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    if (BackendConfig.googleWebClientId.isEmpty) {
      throw const AuthFailure('GOOGLE_CONFIG');
    }

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      // On Web the client ID is read from the official meta tag in
      // web/index.html. Passing it again here causes Google Identity Services
      // to initialize the same client more than once in debug builds.
      clientId: kIsWeb
          ? null
          : defaultTargetPlatform == TargetPlatform.iOS &&
                BackendConfig.googleIosClientId.isNotEmpty
          ? BackendConfig.googleIosClientId
          : null,
      serverClientId: kIsWeb ? null : BackendConfig.googleWebClientId,
    );

    if (kIsWeb) {
      _googleSubscription ??= signIn.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            unawaited(_handleGoogleAuthenticationEvent(event.user));
          }
        },
        onError: (Object error, StackTrace _) {
          googleError = _googleErrorMessage(error);
          notifyListeners();
        },
      );
    }

    _googleInitialized = true;
    googleReady = true;
    googleError = null;
    notifyListeners();
  }

  /// Prepares Google Sign-In before the Web GIS button is rendered.
  ///
  /// On Web, google_sign_in 7.x does not allow authenticate() from a custom
  /// Flutter button. The official GIS button emits authenticationEvents,
  /// which are handled by [_completeGoogleSignIn].
  Future<void> prepareGoogleSignIn() async {
    if (_googleInitialized) return;
    try {
      await _ensureGoogleInitialized();
    } catch (error) {
      // Allow a later retry if initialization failed before completion.
      _googleInitialization = null;
      googleReady = false;
      googleError = _googleErrorMessage(error);
      notifyListeners();
    }
  }

  Future<void> _completeGoogleSignIn(GoogleSignInAccount user) async {
    final idToken = user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure('GOOGLE_CONFIG');
    }
    final postBody = Uri(
      queryParameters: {'id_token': idToken, 'providerId': 'google.com'},
    ).query;
    final data = await _request('signInWithIdp', {
      'postBody': postBody,
      // For Web the actual origin must be authorized in Firebase Auth.
      // Native builds use the Firebase auth domain as the request URI.
      'requestUri': kIsWeb
          ? Uri.base.origin
          : 'https://${BackendConfig.firebaseAuthDomain}',
      'returnSecureToken': true,
    });
    await _acceptTokens(data);
    await reload();
    googleError = null;
    notifyListeners();
  }

  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAccount user,
  ) async {
    try {
      await _completeGoogleSignIn(user);
    } catch (error) {
      googleError = _googleErrorMessage(error);
      notifyListeners();
    }
  }

  String _googleErrorMessage(Object error) {
    if (error is AuthFailure) return error.toString();
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const AuthFailure('CANCELED').toString();
      }
      return const AuthFailure('GOOGLE_CONFIG').toString();
    }
    return const AuthFailure('GOOGLE_CONFIG').toString();
  }

  Future<void> signInGoogle() async {
    await _ensureGoogleInitialized();
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      // Web must use the Google-rendered GIS button instead of authenticate().
      throw const AuthFailure('GOOGLE_UNSUPPORTED');
    }
    try {
      final user = await signIn.authenticate();
      await _completeGoogleSignIn(user);
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AuthFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? 'CANCELED'
            : 'GOOGLE_CONFIG',
      );
    } catch (_) {
      throw const AuthFailure('GOOGLE_CONFIG');
    }
  }

  Future<void> signOut() async {
    googleError = null;
    _idToken = null;
    _refreshToken = null;
    account = null;
    restoreError = null;
    try {
      await _storage.delete(key: _sessionKey);
      if (_googleInitialized) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_googleSubscription?.cancel());
    _client.close();
    super.dispose();
  }
}
