import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.help)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          DoublerCard(child: Text(l10n.offlineNote)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.onboardingHowKey)),
          const SizedBox(height: AppSpacing.sm),
          DoublerCard(child: Text(l10n.officialKeyUrl)),
          const SizedBox(height: AppSpacing.md),
          DoublerButton(
            label: l10n.onboarding,
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
        ],
      ),
    );
  }
}
