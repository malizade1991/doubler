import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../infrastructure/gemini/gemini_config.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final model = ref.watch(geminiModelProvider);
    final voice = ref.watch(voiceIdProvider);

    return DoublerScaffold(
      title: l10n.about,
      body: DoublerPage(
        children: [
          DoublerCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppConstants.brandLatin,
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${l10n.versionLabel} ${AppConstants.appVersion}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                const AudioWaveform(active: true, height: 34),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.engineSummary, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _Row(label: l10n.modelLabel, value: model),
                _Row(label: l10n.voice, value: voice),
                _Row(
                  label: l10n.transport,
                  value: 'wss · ${GeminiConfig.wsPath.split('.').last}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.aboutBody)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.offlineNote)),
          const SizedBox(height: AppSpacing.sm),
          DoublerStatusBanner(
            icon: Icons.shield_outlined,
            message: l10n.privacyBody,
          ),
        ],
      ),
      bottomBar: DoublerActionRow(
        children: [
          DoublerButton(
            label: l10n.help,
            icon: Icons.help_outline,
            variant: DoublerButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const _AboutHelpRoute(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline help entry so "About" can explain failures without a router hop.
class _AboutHelpRoute extends StatelessWidget {
  const _AboutHelpRoute();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DoublerScaffold(
      title: l10n.help,
      body: DoublerPage(
        children: [
          DoublerCard(child: Text(l10n.offlineNote)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.keyWarningLegacy)),
          const SizedBox(height: AppSpacing.sm),
          const DoublerCard(
            child: SelectableText(GeminiConfig.keyConsoleUrl),
          ),
        ],
      ),
    );
  }
}
