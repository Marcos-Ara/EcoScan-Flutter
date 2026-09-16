import 'package:flutter/material.dart';

import 'app.dart';
import 'state/ecoscan_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await EcoScanStore.load();
  runApp(EcoScanApp(store: store));
}
