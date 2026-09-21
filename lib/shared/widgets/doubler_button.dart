import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import 'doubler_scaffold.dart';

enum DoublerButtonVariant { primary, secondary, ghost, destructive }

class DoublerButton extends StatelessWidget {
  const DoublerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DoublerButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DoublerButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final bool busy;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _progressColor(scheme),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (busy) const SizedBox(width: AppSpacing.sm),
        Flexible(child: labelWidget),
      ],
    );

    final VoidCallback? action = _enabled ? _tap : null;

    final Widget button = switch (variant) {
      DoublerButtonVariant.primary => FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          child: content,
        ),
      DoublerButtonVariant.secondary => OutlinedButton(
          onPressed: action,
          child: content,
        ),
      DoublerButtonVariant.ghost => TextButton(
          onPressed: action,
          child: content,
        ),
      DoublerButtonVariant.destructive => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
          ),
          child: content,
        ),
    };

    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }

  Color _progressColor(ColorScheme scheme) {
    return switch (variant) {
      DoublerButtonVariant.primary => scheme.onPrimary,
      DoublerButtonVariant.destructive => scheme.error,
      _ => scheme.primary,
    };
  }

  void _tap() {
    unawaited(HapticFeedback.selectionClick());
    onPressed?.call();
  }
}

/// Round icon button with an explicit selected state (mic mute, transcript…).
class DoublerIconButton extends StatelessWidget {
  const DoublerIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.size = 52,
    this.iconSize = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected
              ? scheme.errorContainer
              : scheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    unawaited(HapticFeedback.selectionClick());
                    onPressed?.call();
                  }
                : null,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: iconSize,
                color: selected
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable pill used for tone / voice / theme / performance choices.
///
/// It replaces `ChoiceChip` where the tap target or the selection contrast was
/// too small to hit reliably with one thumb.
class DoublerChoicePill extends StatelessWidget {
  const DoublerChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tone = color ?? scheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tone.withValues(alpha: 0.16) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillShape,
          side: BorderSide(
            color: selected ? tone : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onSelected();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? tone : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (color != null && !selected)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                    child: _Swatch(color: color!),
                  ),
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.check, size: 18, color: tone),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Two-value switch used in settings rows where a full `SwitchListTile` is too
/// heavy (e.g. "smart ducking" inside a card).
class DoublerSwitchRow extends StatelessWidget {
  const DoublerSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DoublerCardSurface(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
    );
  }
}
