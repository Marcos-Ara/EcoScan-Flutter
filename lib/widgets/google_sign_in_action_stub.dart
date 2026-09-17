import 'package:flutter/material.dart';

import 'google_sign_in_types.dart';

Widget buildGoogleSignInAction({
  required bool busy,
  required bool ready,
  required VoidCallback? onPressed,
  required GoogleCredentialCallback? onCredential,
}) => OutlinedButton.icon(
  onPressed: busy || !ready ? null : onPressed,
  icon: const Text(
    'G',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
  label: const Text('Continuar com Google'),
);
