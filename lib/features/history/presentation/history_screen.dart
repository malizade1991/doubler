import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../application/history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.emptyHistory)),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text(l10n.emptyHistory));
          }
          return ListView.builder(
            padding: AppSpacing.page,
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DoublerCard(
                  onTap: () => context.push('/history/${s.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s.sourceLanguage} → ${s.targetLanguage}'),
                            Text(
                              '${s.startedAt.toIso8601String()} · ${s.duration.inSeconds}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: () => ref
                            .read(historyControllerProvider.notifier)
                            .remove(s.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
