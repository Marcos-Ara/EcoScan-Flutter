import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'screens/main_shell.dart';
import 'services/eco_point_service.dart';
import 'state/eco_point_controller.dart';
import 'state/ecoscan_store.dart';

class EcoScanApp extends StatelessWidget {
  const EcoScanApp({required this.store, super.key});

  final EcoScanStore store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        Provider<EcoPointService>(
          create: (_) => EcoPointService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<EcoPointController>(
          create: (context) => EcoPointController(
            service: context.read<EcoPointService>(),
            store: store,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EcoScan AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const MainShell(),
      ),
    );
  }
}
