import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/detection_record.dart';
import '../state/ecoscan_store.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EcoScanStore>();
    final records = store.detections;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${records.length} ${records.length == 1 ? 'item analisado' : 'itens analisados'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (records.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, store),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _HistoryCard(
                      record: records[index],
                      onDelete: () => store.removeDetection(records[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmClear(
    BuildContext context,
    EcoScanStore store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'As análises e fotos guardadas neste aparelho serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.clearHistory();
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.muted,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma análise ainda',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 7),
            Text(
              'As fotos analisadas pelo scanner aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.onDelete});

  final DetectionRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = File(record.imagePath);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FutureBuilder<bool>(
                future: image.exists(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Image.file(
                      image,
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                    );
                  }
                  return const ColoredBox(
                    color: AppColors.surfaceHigh,
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.category} · Lixeira ${record.bin}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    record.destination,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _formatDate(record.detectedAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} às ${two(date.hour)}:${two(date.minute)}';
}
