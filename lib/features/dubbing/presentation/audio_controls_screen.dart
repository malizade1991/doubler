import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_slider.dart';

class AudioControlsScreen extends ConsumerWidget {
  const AudioControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final original = ref.watch(originalVolumeProvider);
    final dubbed = ref.watch(dubbedVolumeProvider);
    final ducking = ref.watch(smartDuckingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioControls)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          DoublerCard(child: Text(l10n.micModeMixNote)),
          const SizedBox(height: AppSpacing.md),
          DoublerSlider(
            label: l10n.originalVolume,
            value: original,
            onChanged: (v) =>
                ref.read(originalVolumeProvider.notifier).state = v,
          ),
          DoublerSlider(
            label: l10n.dubbedVolume,
            value: dubbed,
            onChanged: (v) =>
                ref.read(dubbedVolumeProvider.notifier).state = v,
          ),
          SwitchListTile(
            title: Text(l10n.smartDucking),
            value: ducking,
            onChanged: (v) =>
                ref.read(smartDuckingProvider.notifier).state = v,
          ),
        ],
      ),
    );
  }
}
