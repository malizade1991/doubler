import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Volume/size slider row with a readable value and a comfortable hit area.
class DoublerSlider extends StatelessWidget {
  const DoublerSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.valueLabel,
    this.icon,
    this.auxiliaryLabel,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  /// Overrides the default "73%" readout (e.g. "20 px").
  final String? valueLabel;
  final IconData? icon;

  /// Optional caption on the trailing side (e.g. "muted while dubbing").
  final String? auxiliaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = '${(value * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            if (auxiliaryLabel != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.sm,
                  end: AppSpacing.sm,
                ),
                child: Text(
                  auxiliaryLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40),
              child: Text(
                valueLabel ?? percent,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        // Negative horizontal padding keeps the thumb itself at least 44dp
        // from the card edge, where it is still easy to grab.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Slider(value: value.clamp(0, 1), onChanged: onChanged),
        ),
      ],
    );
  }
}
