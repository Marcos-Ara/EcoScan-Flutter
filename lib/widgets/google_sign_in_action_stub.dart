import 'package:flutter/material.dart';

Widget buildGoogleSignInAction({
  required bool busy,
  required bool ready,
  required VoidCallback? onPressed,
}) => OutlinedButton.icon(
  onPressed: busy ? null : onPressed,
  icon: const Text(
    'G',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
  label: const Text('Continuar com Google'),
);
