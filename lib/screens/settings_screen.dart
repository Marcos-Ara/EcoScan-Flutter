import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_session.dart';
import '../state/ecoscan_store.dart';
import 'profile_screen.dart';
import 'community_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onOpenMap, super.key});
  final VoidCallback onOpenMap;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<EcoScanStore>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Configurações',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Tema escuro'),
            value: store.darkMode,
            onChanged: store.setDarkMode,
          ),
          SwitchListTile(
            title: const Text('Avisos do aplicativo'),
            subtitle: const Text('Confirmações dentro do EcoScan'),
            value: store.notifications,
            onChanged: store.setNotifications,
          ),
          SwitchListTile(
            title: const Text('Sons do EcoScan'),
            value: store.sounds,
            onChanged: store.setSounds,
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu perfil'),
            subtitle: const Text('Nome, foto, e-mail e senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Idioma: Português (BR)'),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Criadores do projeto'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CreatorsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Abrir EcoPontos'),
            onTap: onOpenMap,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              final auth = context.read<FirebaseSession>();
              store.switchUser(null);
              await auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
