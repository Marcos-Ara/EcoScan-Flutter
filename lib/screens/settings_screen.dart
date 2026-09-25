import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_session.dart';
import '../state/ecoscan_store.dart';
import 'profile_screen.dart';
import 'community_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onOpenMap, super.key});
  final VoidCallback onOpenMap;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<EcoScanStore>();
    final auth = context.watch<AuthSession>();
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
          if (auth.isGuest)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Modo visitante'),
              subtitle: const Text(
                'Sem conta: histórico e preferências ficam neste dispositivo.',
              ),
              trailing: const Icon(Icons.login_rounded),
              onTap: () {
                store.switchUser(null);
                auth.leaveGuest();
              },
            )
          else
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
            title: Text(
              auth.isGuest ? 'Sair do modo visitante' : 'Sair da conta',
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              store.switchUser(null);
              await auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
