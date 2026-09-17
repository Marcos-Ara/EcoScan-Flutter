import 'package:flutter/material.dart';

import 'google_sign_in_action_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_action_web.dart' as platform;

import 'google_sign_in_types.dart';

class GoogleSignInAction extends StatelessWidget {
  const GoogleSignInAction({
    required this.busy,
    required this.ready,
    required this.onPressed,
    required this.onCredential,
    super.key,
  });

  final bool busy;
  final bool ready;
  final VoidCallback? onPressed;
  final GoogleCredentialCallback? onCredential;

  @override
  Widget build(BuildContext context) => platform.buildGoogleSignInAction(
    busy: busy,
    ready: ready,
    onPressed: onPressed,
    onCredential: onCredential,
  );
}
