import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis_id;
import 'package:google_identity_services_web/loader.dart' as gis_loader;

import '../core/backend_config.dart';
import 'google_sign_in_types.dart';

Future<void>? _gisInitialization;
GoogleCredentialCallback? _credentialCallback;
String? _initializedClientId;

void _handleCredential(gis_id.CredentialResponse response) {
  final callback = _credentialCallback;
  final credential = response.credential;
  if (callback != null && credential.isNotEmpty) {
    unawaited(callback(credential));
  }
}

Future<void> _initializeGis(GoogleCredentialCallback? callback) async {
  _credentialCallback = callback;
  final clientId = BackendConfig.googleWebClientId;
  if (clientId.isEmpty) {
    throw StateError('GOOGLE_WEB_CLIENT_ID não configurado.');
  }

  if (_gisInitialization != null && _initializedClientId == clientId) {
    return _gisInitialization!;
  }

  _initializedClientId = clientId;
  _gisInitialization = () async {
    await gis_loader.loadWebSdk();

    final configuration = gis_id.IdConfiguration(
      client_id: clientId,
      callback: _handleCredential,
      auto_select: false,
      cancel_on_tap_outside: false,
      ux_mode: gis_id.UxMode.popup,
      itp_support: true,
    );

    // google_identity_services_web 0.3.3+1 ainda não expõe este campo no
    // construtor, mas o GIS atual aceita use_fedcm_for_button. Em Chrome
    // Android moderno isso mantém o fluxo dentro da UX controlada pelo
    // navegador e evita a janela/aba OAuth que pode ficar presa em POST e
    // terminar em ERR_CACHE_MISS.
    configuration['use_fedcm_for_button'] = true.toJS;
    configuration['button_auto_select'] = false.toJS;

    gis_id.id.initialize(configuration);
  }();

  try {
    await _gisInitialization;
  } catch (_) {
    _gisInitialization = null;
    _initializedClientId = null;
    rethrow;
  }
}

Widget buildGoogleSignInAction({
  required bool busy,
  required bool ready,
  required VoidCallback? onPressed,
  required GoogleCredentialCallback? onCredential,
}) {
  if (!ready) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Text(
        'G',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      label: const Text('Continuar com Google'),
    );
  }

  return _GoogleWebButton(
    busy: busy,
    onCredential: onCredential,
  );
}

class _GoogleWebButton extends StatefulWidget {
  const _GoogleWebButton({
    required this.busy,
    required this.onCredential,
  });

  final bool busy;
  final GoogleCredentialCallback? onCredential;

  @override
  State<_GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<_GoogleWebButton> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _GoogleWebButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _credentialCallback = widget.onCredential;
  }

  Future<void> _prepare() async {
    try {
      await _initializeGis(widget.onCredential);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar o acesso Google.';
          _ready = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        _error!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    if (!_ready) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: widget.busy,
      child: Opacity(
        opacity: widget.busy ? 0.55 : 1,
        child: Center(
          child: SizedBox(
            width: 320,
            height: 44,
            child: HtmlElementView.fromTagName(
              key: const ValueKey('ecoscan-google-gis-button'),
              tagName: 'div',
              onElementCreated: (Object element) {
                gis_id.id.renderButton(
                  element,
                  gis_id.GsiButtonConfiguration(
                    type: gis_id.ButtonType.standard,
                    theme: gis_id.ButtonTheme.outline,
                    size: gis_id.ButtonSize.large,
                    text: gis_id.ButtonText.continue_with,
                    shape: gis_id.ButtonShape.pill,
                    logo_alignment: gis_id.ButtonLogoAlignment.left,
                    width: 320,
                    locale: 'pt-BR',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
