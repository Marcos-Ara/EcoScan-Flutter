import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleSignInAction({
  required bool busy,
  required bool ready,
  required VoidCallback? onPressed,
}) {
  if (!ready) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      label: const Text('Continuar com Google'),
    );
  }

  return IgnorePointer(
    ignoring: busy,
    child: Opacity(
      opacity: busy ? 0.55 : 1,
      child: const _GoogleWebButton(),
    ),
  );
}

class _GoogleWebButton extends StatefulWidget {
  const _GoogleWebButton();

  @override
  State<_GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<_GoogleWebButton> {
  late final Widget _button;

  @override
  void initState() {
    super.initState();

    _button = web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        logoAlignment: web.GSIButtonLogoAlignment.left,
        minimumWidth: 320,
        locale: 'pt-BR',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: _button);
  }
}