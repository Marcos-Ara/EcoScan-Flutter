import 'package:flutter/material.dart';

import 'google_sign_in_action_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_action_web.dart' as platform;

class GoogleSignInAction extends StatelessWidget {
  const GoogleSignInAction({
    required this.busy,
    required this.ready,
    required this.onPressed,
    super.key,
  });

  final bool busy;
  final bool ready;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => platform.buildGoogleSignInAction(
    busy: busy,
    ready: ready,
    onPressed: onPressed,
  );
}
