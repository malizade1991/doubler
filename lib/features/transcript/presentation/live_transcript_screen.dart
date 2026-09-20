import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/mixed_direction_text.dart';
import '../application/transcript_controller.dart';

class LiveTranscriptScreen extends ConsumerWidget {
  const LiveTranscriptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final segments = ref.watch(transcriptControllerProvider).segments;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.liveTranscript)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.page,
              itemCount: segments.length,
              itemBuilder: (context, i) {
                final s = segments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: DoublerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          s.timestampLabel,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.sourceLanguage),
                        MixedDirectionText(text: s.sourceText),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.targetLanguage),
                        MixedDirectionText(text: s.translatedText),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: AppSpacing.page,
            child: Column(
              children: [
                DoublerButton(
                  label: l10n.copy,
                  onPressed: () async {
                    final text = ref
                        .read(transcriptControllerProvider.notifier)
                        .exportTxt(
                          sourceLabel: l10n.sourceLanguage,
                          targetLabel: l10n.targetLanguage,
                        );
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copied)),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DoublerButton(
                  label: l10n.exportTranscript,
                  variant: DoublerButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.exportTranscript),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
