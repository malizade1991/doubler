import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/mixed_direction_text.dart';
import '../application/transcript_controller.dart';

class LiveTranscriptScreen extends ConsumerWidget {
  const LiveTranscriptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final segments = ref.watch(transcriptControllerProvider).segments;

    return DoublerScaffold(
      title: l10n.liveTranscript,
      actions: [
        IconButton(
          tooltip: l10n.clear,
          onPressed: segments.isEmpty
              ? null
              : () => ref
                  .read(transcriptControllerProvider.notifier)
                  .startSession(),
          icon: const Icon(Icons.cleaning_services_outlined),
        ),
      ],
      body: segments.isEmpty
          ? DoublerEmptyState(
              icon: Icons.subtitles_outlined,
              title: l10n.transcriptEmpty,
              message: l10n.transcriptEmptyHint,
              action: DoublerButton(
                label: l10n.startLiveDubbing,
                expanded: false,
                icon: Icons.graphic_eq_rounded,
                onPressed: () => context.go(AppRoutes.liveDubbing),
              ),
            )
          : DoublerPage(
              // Newest caption first: the user should not have to scroll to find
              // what was just said.
              children: [
                for (final segment in segments.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: DoublerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  segment.timestampLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.copy,
                                onPressed: () => _copy(
                                  context,
                                  '${segment.sourceText}\n${segment.translatedText}',
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          MixedDirectionText(
                            text: segment.sourceText,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: AppRadii.card,
                            ),
                            child: MixedDirectionText(
                              text: segment.translatedText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
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
          Row(
            children: [
              Expanded(
                child: DoublerButton(
                  label: l10n.copy,
                  icon: Icons.copy_rounded,
                  onPressed: segments.isEmpty
                      ? null
                      : () => _copy(
                          context,
                          ref
                              .read(transcriptControllerProvider.notifier)
                              .exportTxt(
                                sourceLabel: l10n.sourceLanguage,
                                targetLabel: l10n.targetLanguage,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DoublerButton(
                  label: l10n.exportTranscript,
                  variant: DoublerButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.exportTranscript),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    showDoublerToast(context, AppLocalizations.of(context).copied);
  }
}
