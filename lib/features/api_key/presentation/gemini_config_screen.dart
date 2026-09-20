import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';

class GeminiConfigScreen extends StatelessWidget {
  const GeminiConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.geminiConfig)),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            DoublerCard(child: Text(l10n.byokExplainer)),
            const SizedBox(height: AppSpacing.md),
            DoublerButton(
              label: l10n.apiKeySetup,
              onPressed: () => context.push(AppRoutes.apiKeySetup),
            ),
          ],
        ),
      ),
    );
  }
}
