import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/mixed_direction_text.dart';
import '../../transcript/application/transcript_controller.dart';
import '../application/history_controller.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(historyControllerProvider).valueOrNull ?? [];
    final session = sessions.where((s) => s.id == id).firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.history)),
        body: Center(child: Text(l10n.emptyHistory)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          DoublerCard(
            child: Text(
              '${session.sourceLanguage} → ${session.targetLanguage}\n'
              '${l10n.duration}: ${session.duration.inSeconds}s',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final seg in session.transcript)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DoublerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(seg.timestampLabel),
                    MixedDirectionText(text: seg.sourceText),
                    MixedDirectionText(text: seg.translatedText),
                  ],
                ),
              ),
            ),
          DoublerButton(
            label: l10n.exportTranscript,
            onPressed: () {
              ref.read(transcriptControllerProvider.notifier)
                ..startSession();
              for (final seg in session.transcript) {
                ref.read(transcriptControllerProvider.notifier)
                  ..addSource(seg.sourceText, isFinal: true)
                  ..addTranslation(seg.translatedText, isFinal: true);
              }
              context.push(AppRoutes.exportTranscript);
            },
          ),
        ],
      ),
    );
  }
}
