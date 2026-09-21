import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import 'doubler_scaffold.dart';

enum DoublerMood { info, success, warning, error }

/// Inline status strip: validation results, key warnings, session errors.
class DoublerStatusBanner extends StatelessWidget {
  const DoublerStatusBanner({
    super.key,
    required this.message,
    this.mood = DoublerMood.info,
    this.action,
    this.icon,
  });

  final String message;
  final DoublerMood mood;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, defaultIcon) = switch (mood) {
      DoublerMood.info => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          Icons.info_outline,
        ),
      DoublerMood.success => (
          AppColors.success.withValues(alpha: 0.16),
          scheme.onSurface,
          Icons.check_circle_outline,
        ),
      DoublerMood.warning => (
          AppColors.warning.withValues(alpha: 0.18),
          scheme.onSurface,
          Icons.error_outline,
        ),
      DoublerMood.error => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.highlight_off,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.card,
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon ?? defaultIcon, color: foreground, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: foreground),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Friendly placeholder for lists with nothing in them yet.
class DoublerEmptyState extends StatelessWidget {
  const DoublerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Small coloured pill used for "key configured", "live", latency bands…
class DoublerPill extends StatelessWidget {
  const DoublerPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: dense ? 3 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillShape,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: tone),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Big progress dot row for the connecting state.
class DoublerBusyLine extends StatelessWidget {
  const DoublerBusyLine({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Card + row helper used by screens that render a preview panel.
class DoublerPanel extends StatelessWidget {
  const DoublerPanel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = AppSpacing.card,
    this.tone,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DoublerCardSurface(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: text.labelMedium?.copyWith(
                      color: tone ?? Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}
