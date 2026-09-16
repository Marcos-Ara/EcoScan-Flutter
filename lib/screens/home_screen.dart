import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/eco_point_controller.dart';
import '../state/ecoscan_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenMap,
    required this.onOpenScanner,
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EcoScanStore>();
    final ecoPoints = context.watch<EcoPointController>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverList.list(
              children: [
                const _Header(),
                const SizedBox(height: 24),
                _HeroCard(onScan: onOpenScanner, onMap: onOpenMap),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        value: '${ecoPoints.totalCount}',
                        label: 'EcoPontos salvos',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        value: '${store.scanCount}',
                        label: 'Itens analisados',
                        icon: Icons.auto_awesome_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'O que você quer fazer?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.map_rounded,
                  title: 'Encontrar EcoPontos',
                  subtitle: 'Veja todos os locais próximos e explore qualquer região do mapa.',
                  color: AppColors.blue,
                  onTap: onOpenMap,
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Identificar um resíduo',
                  subtitle: 'Abra a câmera e receba uma orientação básica de descarte.',
                  color: AppColors.primary,
                  onTap: onOpenScanner,
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.history_rounded,
                  title: 'Consultar histórico',
                  subtitle:
                      'Reveja as análises que ficam guardadas neste aparelho.',
                  color: const Color(0xFFF4B942),
                  onTap: onOpenHistory,
                ),
                const SizedBox(height: 18),
                const _PrivacyNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Color(0xFF07100B),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoScan AI',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                'Descarte melhor. Recicle mais.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: AppColors.primary, size: 8),
              SizedBox(width: 6),
              Text(
                'MOBILE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onScan, required this.onMap});

  final VoidCallback onScan;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173C24), Color(0xFF102217)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2F6240)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x264FC968),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'RECICLAGEM INTELIGENTE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Seu guia de descarte\nna palma da mão.',
            style: TextStyle(
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Identifique materiais e encontre onde levar cada item.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('Escanear'),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.background,
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('EcoPontos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: Color(0xFF477455)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: AppColors.muted, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'As análises e o histórico desta base ficam no aparelho. Nenhuma conta é necessária.',
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }
}
