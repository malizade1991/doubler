import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../api_key/application/api_key_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <_OnboardingStep>[
      _OnboardingStep(Icons.hearing_active, l10n.onboardingWhat, l10n.tagline),
      _OnboardingStep(
        Icons.vpn_key_outlined,
        l10n.onboardingWhyKey,
        l10n.byokExplainer,
      ),
      _OnboardingStep(
        Icons.add_link,
        l10n.onboardingHowKey,
        l10n.officialKeyUrl,
      ),
      _OnboardingStep(Icons.paste_rounded, l10n.onboardingWherePaste, ''),
      _OnboardingStep(
        Icons.privacy_tip_outlined,
        l10n.onboardingPrivacy,
        l10n.keyNeverLeaves,
      ),
      _OnboardingStep(
        Icons.hub_outlined,
        l10n.onboardingDirectGoogle,
        l10n.networkRequiredNote,
      ),
    ];
    final isLast = _page == steps.length - 1;
    final hasKey =
        ref.watch(apiKeyControllerProvider).valueOrNull?.hasKey ?? false;

    return DoublerScaffold(
      title: l10n.onboarding,
      actions: [
        TextButton(
          onPressed: () => context.go(hasKey ? AppRoutes.home : AppRoutes.apiKeySetup),
          child: Text(l10n.skip),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: steps.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  padding: AppSpacing.page,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${index + 1} / ${steps.length}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.signal.withValues(alpha: 0.12),
                        child: Icon(step.icon, size: 30, color: AppColors.signal),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        step.headline,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (step.detail.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        DoublerCard(
                          child: Text(
                            step.detail,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          _Dots(count: steps.length, index: _page, onTap: _goTo),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
      bottomBar: DoublerActionRow(
        children: [
          Row(
            children: [
              if (_page > 0)
                Expanded(
                  child: DoublerButton(
                    label: l10n.back,
                    variant: DoublerButtonVariant.secondary,
                    onPressed: () => _goTo(_page - 1),
                  ),
                ),
              if (_page > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DoublerButton(
                  label: isLast ? l10n.apiKeySetup : l10n.next,
                  icon: isLast ? Icons.vpn_key_outlined : null,
                  onPressed: () {
                    if (isLast) {
                      context.go(AppRoutes.apiKeySetup);
                    } else {
                      _goTo(_page + 1);
                    }
                  },
                ),
              ),
            ],
          ),
          if (hasKey) ...[
            const SizedBox(height: AppSpacing.sm),
            DoublerButton(
              label: l10n.continueToHome,
              variant: DoublerButtonVariant.ghost,
              icon: Icons.home_outlined,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onTap});

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '${index + 1} / $count',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == index ? 26 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == index ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep(this.icon, this.headline, this.detail);

  final IconData icon;
  final String headline;
  final String detail;
}
