import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<({IconData icon, String key})> _points =
      <({IconData icon, String key})>[
    (icon: Icons.mic, key: 'privacyMic'),
    (icon: Icons.key, key: 'privacyKey'),
    (icon: Icons.cloud_off, key: 'privacyNoServer'),
    (icon: Icons.delete_outline, key: 'privacyErase'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DoublerScaffold(
      title: l10n.privacy,
      body: DoublerPage(
        children: [
          DoublerStatusBanner(
            icon: Icons.privacy_tip_outlined,
            message: l10n.privacyBody,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final point in _points)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: DoublerCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.signal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(point.icon, size: 18, color: AppColors.signal),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.message(point.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.privacyFooter,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
