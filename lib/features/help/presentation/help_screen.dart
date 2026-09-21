import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../infrastructure/gemini/gemini_config.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_dialogs.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<({IconData icon, String titleKey, String bodyKey})> _topics =
      <({IconData icon, String titleKey, String bodyKey})>[
    (
      icon: Icons.vpn_key_outlined,
      titleKey: 'helpKeyTitle',
      bodyKey: 'helpKeyBody',
    ),
    (
      icon: Icons.network_check,
      titleKey: 'helpNetworkTitle',
      bodyKey: 'helpNetworkBody',
    ),
    (
      icon: Icons.graphic_eq,
      titleKey: 'helpSilenceTitle',
      bodyKey: 'helpSilenceBody',
    ),
    (
      icon: Icons.headphones,
      titleKey: 'helpFeedbackTitle',
      bodyKey: 'helpFeedbackBody',
    ),
    (
      icon: Icons.battery_charging_full,
      titleKey: 'helpBackgroundTitle',
      bodyKey: 'helpBackgroundBody',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DoublerScaffold(
      title: l10n.help,
      body: DoublerPage(
        children: [
          DoublerStatusBanner(
            icon: Icons.chat_bubble_outline,
            message: l10n.helpLanguageNote,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final topic in _topics)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DoublerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(topic.icon, color: AppColors.signal, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.message(topic.titleKey),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.message(topic.bodyKey),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          DoublerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.keyHowToTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  GeminiConfig.keyConsoleUrl,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomBar: DoublerActionRow(
        children: [
          Row(
            children: [
              Expanded(
                child: DoublerButton(
                  label: l10n.apiKeySetup,
                  icon: Icons.vpn_key_outlined,
                  onPressed: () => context.push(AppRoutes.apiKeySetup),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DoublerButton(
                  label: l10n.copy,
                  icon: Icons.copy_rounded,
                  variant: DoublerButtonVariant.secondary,
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: GeminiConfig.keyConsoleUrl),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    showDoublerToast(context, l10n.copied);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
