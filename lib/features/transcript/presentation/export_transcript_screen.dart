import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../application/transcript_controller.dart';
import '../application/transcript_export.dart';

/// Copy/share a session. Everything stays on device: the payload goes to the
/// clipboard, never to a DOUBLER server (there is none).
class ExportTranscriptScreen extends ConsumerStatefulWidget {
  const ExportTranscriptScreen({super.key});

  @override
  ConsumerState<ExportTranscriptScreen> createState() =>
      _ExportTranscriptScreenState();
}

class _ExportTranscriptScreenState extends ConsumerState<ExportTranscriptScreen> {
  bool _bilingual = true;
  ExportKind _format = ExportKind.txt;
  String _preview = '';

  String _render() {
    final segments = ref.read(transcriptControllerProvider).segments;
    final l10n = AppLocalizations.of(context);
    return switch (_format) {
      ExportKind.txt => TranscriptExport.txt(
          segments,
          sourceLabel: l10n.sourceLanguage,
          targetLabel: l10n.targetLanguage,
          bilingual: _bilingual,
        ),
      ExportKind.srt => TranscriptExport.srt(segments, bilingual: _bilingual),
      ExportKind.json => TranscriptExport.jsonDoc(segments),
    };
  }

  Future<void> _copy() async {
    final text = _render();
    setState(() => _preview = text);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    showDoublerToast(context, AppLocalizations.of(context).copied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final segments = ref.watch(transcriptControllerProvider).segments;
    final hasContent = segments.isNotEmpty;

    return DoublerScaffold(
      title: l10n.exportTranscript,
      body: DoublerPage(
        children: [
          if (!hasContent)
            DoublerEmptyState(
              icon: Icons.download_outlined,
              title: l10n.exportEmpty,
              message: l10n.exportEmptyHint,
            )
          else ...[
            DoublerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.exportFormat,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final format in ExportKind.values)
                        DoublerChoicePill(
                          label: _label(format),
                          selected: format == _format,
                          onSelected: () => setState(() => _format = format),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    value: _bilingual,
                    onChanged: (v) => setState(() => _bilingual = v),
                    title: Text(l10n.bilingual),
                    subtitle: Text(l10n.bilingualHint),
                    contentPadding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.card,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DoublerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.previewLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${l10n.exportSegments}: ${segments.length}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: AppRadii.card,
                    ),
                    child: SelectableText(
                      _preview.isEmpty ? l10n.previewEmpty : _preview,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  onPressed: hasContent ? _copy : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DoublerButton(
                  label: l10n.exportRefresh,
                  variant: DoublerButtonVariant.secondary,
                  icon: Icons.refresh,
                  onPressed: hasContent
                      ? () => setState(() => _preview = _render())
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(ExportKind format) {
    final l10n = AppLocalizations.of(context);
    return switch (format) {
      ExportKind.txt => l10n.exportTxt,
      ExportKind.srt => l10n.exportSrt,
      ExportKind.json => l10n.exportJson,
    };
  }
}
