import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/performance_mode.dart';
import '../../../domain/models/translation_tone.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../api_key/application/api_key_controller.dart';
import '../../history/application/history_controller.dart';
import 'subtitle_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tone = ref.watch(translationToneProvider);
    final theme = ref.watch(themeModeProvider);
    final voice = ref.watch(voiceIdProvider);
    final perf = ref.watch(performanceModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          DoublerCard(
            onTap: () => context.push(AppRoutes.languageSelection),
            child: Text(l10n.languageSelection),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.appearance, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                label: Text(l10n.themeSystem),
                selected: theme == ThemeMode.system,
                onSelected: (_) =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.system,
              ),
              ChoiceChip(
                label: Text(l10n.themeLight),
                selected: theme == ThemeMode.light,
                onSelected: (_) =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.light,
              ),
              ChoiceChip(
                label: Text(l10n.themeDark),
                selected: theme == ThemeMode.dark,
                onSelected: (_) =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.tone, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final value in TranslationTone.values)
                ChoiceChip(
                  label: Text(_toneLabel(l10n, value)),
                  selected: tone == value,
                  onSelected: (_) =>
                      ref.read(translationToneProvider.notifier).state = value,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.voice, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final id in geminiVoices)
                ChoiceChip(
                  label: Text(id),
                  selected: voice == id,
                  onSelected: (_) =>
                      ref.read(voiceIdProvider.notifier).state = id,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.performance, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                label: Text(l10n.perfLow),
                selected: perf == PerformanceMode.lowLatency,
                onSelected: (_) => ref
                    .read(performanceModeProvider.notifier)
                    .state = PerformanceMode.lowLatency,
              ),
              ChoiceChip(
                label: Text(l10n.perfBalanced),
                selected: perf == PerformanceMode.balanced,
                onSelected: (_) => ref
                    .read(performanceModeProvider.notifier)
                    .state = PerformanceMode.balanced,
              ),
              ChoiceChip(
                label: Text(l10n.perfQuality),
                selected: perf == PerformanceMode.quality,
                onSelected: (_) => ref
                    .read(performanceModeProvider.notifier)
                    .state = PerformanceMode.quality,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SubtitleSettingsPanel(),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            onTap: () => context.push(AppRoutes.audioControls),
            child: Text(l10n.audioControls),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerCard(
            onTap: () => context.push(AppRoutes.geminiConfig),
            child: Text(l10n.geminiConfig),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerCard(
            onTap: () => context.push(AppRoutes.privacy),
            child: Text(l10n.privacy),
          ),
          const SizedBox(height: AppSpacing.lg),
          DoublerButton(
            label: l10n.clearHistory,
            variant: DoublerButtonVariant.secondary,
            onPressed: () =>
                ref.read(historyControllerProvider.notifier).clearAll(),
          ),
          const SizedBox(height: AppSpacing.sm),
          DoublerButton(
            label: l10n.clearAllData,
            variant: DoublerButtonVariant.ghost,
            onPressed: () async {
              await ref.read(historyControllerProvider.notifier).clearAll();
              await ref.read(apiKeyControllerProvider.notifier).delete();
            },
          ),
        ],
      ),
    );
  }

  String _toneLabel(AppLocalizations l10n, TranslationTone tone) {
    return switch (tone) {
      TranslationTone.casual => l10n.toneCasual,
      TranslationTone.natural => l10n.toneNatural,
      TranslationTone.formal => l10n.toneFormal,
      TranslationTone.professional => l10n.toneProfessional,
    };
  }
}
