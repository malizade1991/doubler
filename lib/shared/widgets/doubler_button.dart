import 'package:flutter/material.dart';

enum DoublerButtonVariant { primary, secondary, ghost }

class DoublerButton extends StatelessWidget {
  const DoublerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DoublerButtonVariant.primary,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DoublerButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      DoublerButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          child: child,
        ),
      DoublerButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      DoublerButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          child: child,
        ),
    };

    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
