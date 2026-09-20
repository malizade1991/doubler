import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import 'doubler_button.dart';
import 'doubler_card.dart';

/// Temporary shell used until each feature is implemented in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.showHomeLink = true,
  });

  final String title;
  final bool showHomeLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: AppSpacing.page,
          child: DoublerCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppConstants.brandLatin,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (showHomeLink) ...[
                  const SizedBox(height: AppSpacing.lg),
                  DoublerButton(
                    label: AppConstants.brandLatin,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
