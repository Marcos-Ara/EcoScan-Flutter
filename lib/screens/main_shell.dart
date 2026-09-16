import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'scanner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  Widget _currentScreen() {
    return switch (_selectedIndex) {
      0 => HomeScreen(
        onOpenMap: () => setState(() => _selectedIndex = 1),
        onOpenScanner: () => setState(() => _selectedIndex = 2),
        onOpenHistory: () => setState(() => _selectedIndex = 3),
      ),
      1 => const EcoPointsScreen(),
      2 => const ScannerScreen(),
      _ => const HistoryScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _currentScreen(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'EcoPontos',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak_rounded),
            selectedIcon: Icon(Icons.center_focus_strong_rounded),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
