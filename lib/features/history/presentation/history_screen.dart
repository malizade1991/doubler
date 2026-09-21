import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/dubbing_session.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../application/history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(historyControllerProvider);

    return DoublerScaffold(
      title: l10n.history,
      actions: [
        IconButton(
          tooltip: l10n.clearHistory,
          onPressed: () => _clearAll(context, ref),
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _HistoryEmpty(l10n: l10n),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _HistoryEmpty(l10n: l10n);
          }
          return DoublerPage(
            children: [
              for (final session in sessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: DoublerCard(
                    onTap: () => context.push('/history/${session.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${LanguageCatalog.byCode(session.sourceLanguage).nativeName}'
                                ' → '
                                '${LanguageCatalog.byCode(session.targetLanguage).nativeName}',
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DoublerPill(
                              label: _statusLabel(l10n, session.status),
                              dense: true,
                              color: session.status == SessionStatus.completed
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${l10n.duration}: ${session.duration.inSeconds}s'
                          ' · ${session.transcript.length} · ${_formatDate(session.startedAt)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.transcript.isEmpty
                                    ? '—'
                                    : session.transcript.first.sourceText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            DoublerIconButton(
                              icon: Icons.delete_outline,
                              tooltip: l10n.delete,
                              onPressed: () => ref
                                  .read(historyControllerProvider.notifier)
                                  .remove(session.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              DoublerButton(
                label: l10n.startLiveDubbing,
                icon: Icons.graphic_eq_rounded,
                onPressed: () => context.push(AppRoutes.liveDubbing),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _statusLabel(AppLocalizations l10n, SessionStatus status) {
    return switch (status) {
      SessionStatus.completed => l10n.sessionCompleted,
      SessionStatus.error => l10n.sessionError,
      SessionStatus.interrupted => l10n.sessionInterrupted,
    };
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}/$month/$day $hour:$minute';
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDoublerConfirm(
      context: context,
      title: l10n.clearHistory,
      body: l10n.confirmClearHistoryBody,
      confirmLabel: l10n.clearHistory,
      cancelLabel: l10n.cancel,
    );
    if (!ok) {
      return;
    }
    await ref.read(historyControllerProvider.notifier).clearAll();
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DoublerEmptyState(
      icon: Icons.history,
      title: l10n.emptyHistory,
      message: l10n.historyEmptyHint,
      action: DoublerButton(
        label: l10n.startLiveDubbing,
        expanded: false,
        icon: Icons.graphic_eq_rounded,
        onPressed: () => context.push(AppRoutes.liveDubbing),
      ),
    );
  }
}
