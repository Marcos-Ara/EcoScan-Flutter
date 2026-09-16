import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleSignInAction({
  required bool busy,
  required bool ready,
  required VoidCallback? onPressed,
}) {
  if (!ready) {
    return const OutlinedButton.icon(
      onPressed: null,
      icon: Text(
        'G',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      label: Text('Continuar com Google'),
    );
  }

  // On Web the Google Identity Services SDK requires its own rendered button.
  // A custom Flutter button calling authenticate() is explicitly unsupported.
  return IgnorePointer(
    ignoring: busy,
    child: Opacity(
      opacity: busy ? 0.55 : 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(1.0, 400.0).toDouble()
              : 320.0;
          return Center(
            child: web.renderButton(
              configuration: web.GSIButtonConfiguration(
                type: web.GSIButtonType.standard,
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                text: web.GSIButtonText.continueWith,
                shape: web.GSIButtonShape.pill,
                logoAlignment: web.GSIButtonLogoAlignment.left,
                minimumWidth: width,
                locale: 'pt-BR',
              ),
            ),
          );
        },
      ),
    ),
  );
}
