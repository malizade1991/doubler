import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      l10n.onboardingWhat,
      l10n.onboardingWhyKey,
      l10n.onboardingHowKey,
      l10n.onboardingWherePaste,
      l10n.onboardingPrivacy,
      l10n.onboardingDirectGoogle,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboarding)),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            Expanded(
              child: DoublerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_page + 1} / ${pages.length}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      pages[_page],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.byokExplainer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (_page > 0)
                  Expanded(
                    child: DoublerButton(
                      label: l10n.back,
                      variant: DoublerButtonVariant.secondary,
                      onPressed: () => setState(() => _page--),
                    ),
                  ),
                if (_page > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DoublerButton(
                    label: _page == pages.length - 1
                        ? l10n.apiKeySetup
                        : l10n.next,
                    onPressed: () {
                      if (_page == pages.length - 1) {
                        context.go(AppRoutes.apiKeySetup);
                      } else {
                        setState(() => _page++);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
