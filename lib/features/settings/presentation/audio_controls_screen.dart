import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/doubler_slider.dart';

class AudioControlsScreen extends ConsumerWidget {
  const AudioControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final original = ref.watch(originalVolumeProvider);
    final dubbed = ref.watch(dubbedVolumeProvider);
    final ducking = ref.watch(smartDuckingProvider);

    return DoublerScaffold(
      title: l10n.audioControls,
      body: DoublerPage(
        children: [
          DoublerStatusBanner(
            icon: Icons.graphic_eq,
            message: l10n.micModeMixNote,
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DoublerSectionHeader(
                  label: l10n.levels,
                  topGap: 0,
                ),
                DoublerSlider(
                  label: l10n.originalVolume,
                  icon: Icons.mic_none,
                  value: original,
                  auxiliaryLabel: ducking ? l10n.duckingOn : null,
                  onChanged: (v) =>
                      ref.read(originalVolumeProvider.notifier).state = v,
                ),
                const SizedBox(height: AppSpacing.sm),
                DoublerSlider(
                  label: l10n.dubbedVolume,
                  icon: Icons.record_voice_over_outlined,
                  value: dubbed,
                  onChanged: (v) =>
                      ref.read(dubbedVolumeProvider.notifier).state = v,
                ),
                const SizedBox(height: AppSpacing.md),
                DoublerSwitchRow(
                  title: l10n.smartDucking,
                  subtitle: l10n.smartDuckingHint,
                  value: ducking,
                  onChanged: (v) =>
                      ref.read(smartDuckingProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.outputRouting,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.outputRoutingNote,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
