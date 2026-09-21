import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/mixed_direction_text.dart';
import '../../transcript/application/transcript_controller.dart';
import '../application/history_controller.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sessions = ref.watch(historyControllerProvider).valueOrNull ?? [];
    final session = sessions.where((s) => s.id == id).firstOrNull;

    if (session == null) {
      return DoublerScaffold(
        title: l10n.history,
        body: DoublerEmptyState(
          icon: Icons.event_busy_outlined,
          title: l10n.emptyHistory,
          message: l10n.historyMissingHint,
          action: DoublerButton(
            label: l10n.history,
            expanded: false,
            onPressed: () => context.go(AppRoutes.history),
          ),
        ),
      );
    }

    final source = LanguageCatalog.byCode(session.sourceLanguage).nativeName;
    final target = LanguageCatalog.byCode(session.targetLanguage).nativeName;

    return DoublerScaffold(
      title: l10n.history,
      actions: [
        IconButton(
          tooltip: l10n.delete,
          onPressed: () async {
            final ok = await showDoublerConfirm(
              context: context,
              title: l10n.delete,
              body: l10n.confirmDeleteSessionBody,
              confirmLabel: l10n.delete,
              cancelLabel: l10n.cancel,
            );
            if (!ok) {
              return;
            }
            await ref.read(historyControllerProvider.notifier).remove(id);
            if (!context.mounted) {
              return;
            }
            context.go(AppRoutes.history);
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      body: DoublerPage(
        children: [
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$source → $target',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    DoublerPill(
                      label:
                          '${l10n.duration} ${session.duration.inSeconds}s',
                      icon: Icons.timer_outlined,
                      color: AppColors.signal,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${session.startedAt.toIso8601String().substring(0, 16)}'
                  ' · ${session.transcript.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final segment in session.transcript)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: DoublerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      segment.timestampLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    MixedDirectionText(
                      text: segment.sourceText,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    MixedDirectionText(
                      text: segment.translatedText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomBar: DoublerActionRow(
        children: [
          DoublerButton(
            label: l10n.exportTranscript,
            icon: Icons.download_outlined,
            onPressed: () {
              final controller =
                  ref.read(transcriptControllerProvider.notifier)
                    ..startSession();
              for (final segment in session.transcript) {
                controller
                  ..addSource(segment.sourceText, isFinal: true)
                  ..addTranslation(segment.translatedText, isFinal: true);
              }
              context.push(AppRoutes.exportTranscript);
            },
          ),
        ],
      ),
    );
  }
}
