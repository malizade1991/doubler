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
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../api_key/application/api_key_controller.dart';
import '../../history/application/history_controller.dart';
import 'subtitle_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tone = ref.watch(translationToneProvider);
    final themeMode = ref.watch(themeModeProvider);
    final voice = ref.watch(voiceIdProvider);
    final perf = ref.watch(performanceModeProvider);

    return DoublerScaffold(
      title: l10n.settings,
      body: DoublerPage(
        children: [
          DoublerSectionHeader(label: l10n.appearance, topGap: 0),
          _ChipGroup(
            labels: {
              ThemeMode.system: l10n.themeSystem,
              ThemeMode.light: l10n.themeLight,
              ThemeMode.dark: l10n.themeDark,
            },
            selected: themeMode,
            onSelected: (value) =>
                ref.read(themeModeProvider.notifier).state = value,
          ),
          DoublerSectionHeader(label: l10n.session),
          DoublerTile(
            title: l10n.languageSelection,
            icon: Icons.translate,
            onTap: () => context.push(AppRoutes.languageSelection),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.audioControls,
            icon: Icons.volume_up,
            onTap: () => context.push(AppRoutes.audioControls),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.apiKeySetup,
            icon: Icons.vpn_key_outlined,
            onTap: () => context.push(AppRoutes.apiKeySetup),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.geminiConfig,
            icon: Icons.memory,
            onTap: () => context.push(AppRoutes.geminiConfig),
          ),
          DoublerSectionHeader(label: l10n.tone),
          _ChipGroup<TranslationTone>(
            labels: {
              TranslationTone.casual: l10n.toneCasual,
              TranslationTone.natural: l10n.toneNatural,
              TranslationTone.formal: l10n.toneFormal,
              TranslationTone.professional: l10n.toneProfessional,
            },
            selected: tone,
            onSelected: (value) =>
                ref.read(translationToneProvider.notifier).state = value,
          ),
          DoublerSectionHeader(label: l10n.voice),
          _ChipGroup<String>(
            labels: {for (final id in geminiVoices) id: id},
            selected: voice,
            onSelected: (value) =>
                ref.read(voiceIdProvider.notifier).state = value,
          ),
          DoublerSectionHeader(label: l10n.performance),
          _ChipGroup<PerformanceMode>(
            labels: {
              PerformanceMode.lowLatency: l10n.perfLow,
              PerformanceMode.balanced: l10n.perfBalanced,
              PerformanceMode.quality: l10n.perfQuality,
            },
            selected: perf,
            onSelected: (value) =>
                ref.read(performanceModeProvider.notifier).state = value,
          ),
          DoublerSectionHeader(label: l10n.subtitles),
          const SubtitleSettingsPanel(),
          DoublerSectionHeader(label: l10n.data),
          _DataSection(l10n: l10n),
        ],
      ),
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoublerTile(
          title: l10n.history,
          icon: Icons.history,
          onTap: () => context.push(AppRoutes.history),
        ),
        const SizedBox(height: AppSpacing.xs),
        DoublerTile(
          title: l10n.privacy,
          icon: Icons.privacy_tip_outlined,
          onTap: () => context.push(AppRoutes.privacy),
        ),
        const SizedBox(height: AppSpacing.xs),
        DoublerTile(
          title: l10n.about,
          icon: Icons.info_outline,
          onTap: () => context.push(AppRoutes.about),
        ),
        const SizedBox(height: AppSpacing.md),
        DoublerButton(
          label: l10n.clearHistory,
          variant: DoublerButtonVariant.secondary,
          icon: Icons.delete_sweep_outlined,
          onPressed: () async {
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
            if (!context.mounted) {
              return;
            }
            showDoublerToast(context, l10n.historyCleared);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        DoublerButton(
          label: l10n.clearAllData,
          variant: DoublerButtonVariant.destructive,
          icon: Icons.delete_forever_outlined,
          onPressed: () async {
            final ok = await showDoublerConfirm(
              context: context,
              title: l10n.clearAllData,
              body: l10n.confirmClearAllBody,
              confirmLabel: l10n.clearAllData,
              cancelLabel: l10n.cancel,
            );
            if (!ok) {
              return;
            }
            await ref.read(historyControllerProvider.notifier).clearAll();
            await ref.read(apiKeyControllerProvider.notifier).delete();
            if (!context.mounted) {
              return;
            }
            showDoublerToast(context, l10n.allDataCleared);
          },
        ),
      ],
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in labels.entries)
          DoublerChoicePill(
            label: entry.value,
            selected: entry.key == selected,
            onSelected: () => onSelected(entry.key),
          ),
      ],
    );
  }
}
