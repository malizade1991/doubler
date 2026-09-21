import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../api_key/application/api_key_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final keyState = ref.watch(apiKeyControllerProvider).valueOrNull;
    final hasKey = keyState?.hasKey ?? false;
    final source = LanguageCatalog.byCode(ref.watch(sourceLanguageCodeProvider));
    final target = LanguageCatalog.byCode(ref.watch(targetLanguageCodeProvider));

    return DoublerScaffold(
      title: l10n.appNameLatin,
      actions: [
        IconButton(
          tooltip: l10n.settings,
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      body: DoublerPage(
        children: [
          DoublerCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.appName,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    DoublerPill(
                      label: hasKey ? l10n.keyStatusConfigured : l10n.keyStatusMissing,
                      icon: hasKey ? Icons.check_circle : Icons.error_outline,
                      color: hasKey ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.tagline,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                AudioWaveform(active: hasKey, height: 36),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasKey
                      ? l10n.homeReadyHint
                      : l10n.homeNeedsKeyHint,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                DoublerButton(
                  label: l10n.startLiveDubbing,
                  icon: Icons.graphic_eq_rounded,
                  onPressed: () => context.push(AppRoutes.liveDubbing),
                ),
                if (!hasKey) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DoublerButton(
                    label: l10n.apiKeySetup,
                    variant: DoublerButtonVariant.secondary,
                    icon: Icons.vpn_key_outlined,
                    onPressed: () => context.push(AppRoutes.apiKeySetup),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _LanguagePairCard(source: source, target: target),
          DoublerSectionHeader(label: l10n.quickActions),
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.closed_caption_off,
                  label: l10n.liveSubtitles,
                  onTap: () => context.push(AppRoutes.liveTranscript),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickTile(
                  icon: Icons.history,
                  label: l10n.history,
                  onTap: () => context.push(AppRoutes.history),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.download_outlined,
                  label: l10n.exportTranscript,
                  onTap: () => context.push(AppRoutes.exportTranscript),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickTile(
                  icon: Icons.tune,
                  label: l10n.audioControls,
                  onTap: () => context.push(AppRoutes.audioControls),
                ),
              ),
            ],
          ),
          DoublerSectionHeader(label: l10n.setupSection),
          DoublerTile(
            title: l10n.languageSelection,
            subtitle: '${source.nativeName} → ${target.nativeName}',
            icon: Icons.translate,
            onTap: () => context.push(AppRoutes.languageSelection),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.apiKeySetup,
            subtitle: keyState?.masked ?? l10n.keyStatusMissing,
            icon: Icons.vpn_key_outlined,
            onTap: () => context.push(AppRoutes.apiKeySetup),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.geminiConfig,
            subtitle: ref.watch(geminiModelProvider),
            icon: Icons.memory,
            onTap: () => context.push(AppRoutes.geminiConfig),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.onboarding,
            icon: Icons.school_outlined,
            onTap: () => context.push(AppRoutes.onboarding),
          ),
          DoublerSectionHeader(label: l10n.appSection),
          DoublerTile(
            title: l10n.settings,
            icon: Icons.settings_outlined,
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.privacy,
            icon: Icons.privacy_tip_outlined,
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.help,
            icon: Icons.help_outline,
            onTap: () => context.push(AppRoutes.help),
          ),
          const SizedBox(height: AppSpacing.xs),
          DoublerTile(
            title: l10n.about,
            icon: Icons.info_outline,
            onTap: () => context.push(AppRoutes.about),
          ),
          const SizedBox(height: AppSpacing.md),
          DoublerStatusBanner(
            icon: Icons.privacy_tip_outlined,
            message: l10n.byokExplainer,
          ),
        ],
      ),
    );
  }
}

class _LanguagePairCard extends ConsumerWidget {
  const _LanguagePairCard({required this.source, required this.target});

  final Language source;
  final Language target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DoublerCard(
      onTap: () => context.push(AppRoutes.languageSelection),
      child: Row(
        children: [
          Expanded(
            child: _PairSide(
              flag: source.flag,
              name: source.nativeName,
              label: l10n.sourceLanguage,
            ),
          ),
          IconButton(
            tooltip: l10n.swapLanguages,
            onPressed: () {
              final currentSource = ref.read(sourceLanguageCodeProvider);
              final currentTarget = ref.read(targetLanguageCodeProvider);
              ref.read(sourceLanguageCodeProvider.notifier).state = currentTarget;
              ref.read(targetLanguageCodeProvider.notifier).state =
                  currentSource == 'auto'
                      ? LanguageCatalog.byCode(currentTarget).code
                      : currentSource;
            },
            icon: const Icon(Icons.swap_horiz),
          ),
          Expanded(
            child: _PairSide(
              flag: target.flag,
              name: target.nativeName,
              label: l10n.targetLanguage,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PairSide extends StatelessWidget {
  const _PairSide({
    required this.flag,
    required this.name,
    required this.label,
    this.alignEnd = false,
  });

  final String flag;
  final String name;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text('$flag $name', style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: DoublerCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
