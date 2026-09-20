import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../api_key/application/api_key_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasKey =
        ref.watch(apiKeyControllerProvider).valueOrNull?.hasKey ?? false;
    final items = <_HomeLink>[
      _HomeLink(l10n.startLiveDubbing, AppRoutes.liveDubbing),
      _HomeLink(l10n.liveTranslation, AppRoutes.liveDubbing),
      _HomeLink(l10n.liveSubtitles, AppRoutes.liveTranscript),
      _HomeLink(l10n.conversation, AppRoutes.liveDubbing),
      _HomeLink(l10n.history, AppRoutes.history),
      _HomeLink(l10n.languageSelection, AppRoutes.languageSelection),
      _HomeLink(l10n.audioControls, AppRoutes.audioControls),
      _HomeLink(l10n.settings, AppRoutes.settings),
      _HomeLink(l10n.apiKeySetup, AppRoutes.apiKeySetup),
      _HomeLink(l10n.geminiConfig, AppRoutes.geminiConfig),
      _HomeLink(l10n.onboarding, AppRoutes.onboarding),
      _HomeLink(l10n.exportTranscript, AppRoutes.exportTranscript),
      _HomeLink(l10n.about, AppRoutes.about),
      _HomeLink(l10n.privacy, AppRoutes.privacy),
      _HomeLink(l10n.help, AppRoutes.help),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appNameLatin)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            l10n.appName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AudioWaveform(active: true),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tagline,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasKey ? l10n.keyStatusConfigured : l10n.keyStatusMissing,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            button: true,
            label: l10n.startLiveDubbing,
            child: DoublerButton(
            label: l10n.startLiveDubbing,
            icon: Icons.graphic_eq,
            onPressed: () => context.go(AppRoutes.liveDubbing),
          ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: DoublerCard(
                onTap: () => context.push(item.route),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label)),
                    Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLink {
  const _HomeLink(this.label, this.route);

  final String label;
  final String route;
}
