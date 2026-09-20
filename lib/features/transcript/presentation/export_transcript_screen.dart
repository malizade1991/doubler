import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../application/transcript_controller.dart';
import '../application/transcript_export.dart';

class ExportTranscriptScreen extends ConsumerStatefulWidget {
  const ExportTranscriptScreen({super.key});

  @override
  ConsumerState<ExportTranscriptScreen> createState() =>
      _ExportTranscriptScreenState();
}

class _ExportTranscriptScreenState extends ConsumerState<ExportTranscriptScreen> {
  bool _bilingual = true;
  String _preview = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final segments = ref.watch(transcriptControllerProvider).segments;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTranscript)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          SwitchListTile(
            title: Text(l10n.bilingual),
            value: _bilingual,
            onChanged: (v) => setState(() => _bilingual = v),
          ),
          DoublerButton(
            label: l10n.exportTxt,
            onPressed: () => _copy(
              TranscriptExport.txt(
                segments,
                sourceLabel: l10n.sourceLanguage,
                targetLabel: l10n.targetLanguage,
                bilingual: _bilingual,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerButton(
            label: l10n.exportSrt,
            variant: DoublerButtonVariant.secondary,
            onPressed: () => _copy(
              TranscriptExport.srt(segments, bilingual: _bilingual),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerButton(
            label: l10n.exportJson,
            variant: DoublerButtonVariant.ghost,
            onPressed: () => _copy(TranscriptExport.jsonDoc(segments)),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(_preview),
        ],
      ),
    );
  }

  Future<void> _copy(String text) async {
    setState(() => _preview = text);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }
}
