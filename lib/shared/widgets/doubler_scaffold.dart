import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Page shell that owns the safe-area story for every screen.
///
/// Rules, in one place:
///  * content never starts under a notch/status bar,
///  * content never ends under the Android navigation bar or the iOS home
///    indicator,
///  * a pinned [bottomBar] sits above both the system insets and the keyboard,
///  * scrollable bodies get extra bottom padding so the last row can be
///    scrolled clear of the pinned bar.
class DoublerScaffold extends StatelessWidget {
  const DoublerScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions = const <Widget>[],
    this.bottomBar,
    this.backgroundColor,
    this.showBackButton = true,
    this.keyboardAware = true,
  });

  final Widget body;
  final String? title;
  final List<Widget> actions;
  final Widget? bottomBar;
  final Color? backgroundColor;
  final bool showBackButton;
  final bool keyboardAware;

  @override
  Widget build(BuildContext context) {
    final bar = bottomBar;
    final appBar = title == null
        ? null
        : AppBar(
            title: Text(title!),
            automaticallyImplyLeading: showBackButton,
            actions: actions.isEmpty ? null : actions,
          );

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: keyboardAware,
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              // The bar below already consumes the bottom inset; when there is
              // no bar the scrollable body pads itself (see [DoublerPage]).
              bottom: bar != null,
              top: appBar == null,
              child: body,
            ),
          ),
          if (bar != null) bar,
        ],
      ),
    );
  }
}

/// Scrolling body for the screens' column of cards.
class DoublerPage extends StatelessWidget {
  const DoublerPage({
    super.key,
    required this.children,
    this.reverse = false,
    this.padding,
  });

  final List<Widget> children;
  final bool reverse;

  /// Overrides the default safe-area-aware page padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? AppSpacing.pageScrollable(context),
      reverse: reverse,
      children: children,
    );
  }
}

/// Non-scrolling body with the same horizontal rhythm (used inside sheets).
class DoublerPageBody extends StatelessWidget {
  const DoublerPageBody({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? AppSpacing.pageScrollable(context),
      child: child,
    );
  }
}

/// Pinned action bar: hairline separator, elevated surface and clearance for
/// the notch/home indicator. The body is squeezed by `resizeToAvoidBottomInset`,
/// so the keyboard is handled by [Scaffold] and must not be added here.
class DoublerActionRow extends StatelessWidget {
  const DoublerActionRow({
    super.key,
    required this.children,
    this.center = true,
  });

  final List<Widget> children;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          // Left/right only: the bottom inset comes from AppSpacing.barInsets.
          top: false,
          bottom: false,
          child: Padding(
            padding: AppSpacing.barInsets(context),
            child: Column(
              crossAxisAlignment:
                  center ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section label used inside [DoublerPage].
class DoublerSectionHeader extends StatelessWidget {
  const DoublerSectionHeader({
    super.key,
    required this.label,
    this.action,
    this.topGap = AppSpacing.lg,
  });

  final String label;
  final Widget? action;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Rounded row used for navigation and settings.
class DoublerTile extends StatelessWidget {
  const DoublerTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces the [icon] circle with an arbitrary widget (a flag, an avatar…).
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final iconColor = destructive
        ? scheme.error
        : selected
            ? scheme.primary
            : scheme.onSurfaceVariant;

    return DoublerCardSurface(
      onTap: onTap,
      selected: selected,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ] else if (icon != null) ...[
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: destructive
                      ? text.bodyLarge?.copyWith(color: scheme.error)
                      : text.bodyLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            const DoublerChevron(),
          ],
        ],
      ),
    );
  }
}

/// Card surface with an optional tap target. Used by [DoublerTile] and
/// screens that need the same resting style.
class DoublerCardSurface extends StatelessWidget {
  const DoublerCardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.45)
            : Theme.of(context).cardTheme.color,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: card,
      ),
    );
  }
}

/// Trailing chevron that points the right way in RTL locales.
class DoublerChevron extends StatelessWidget {
  const DoublerChevron({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.scale(
      scaleX: rtl ? -1 : 1,
      child: Icon(
        Icons.chevron_right,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}
