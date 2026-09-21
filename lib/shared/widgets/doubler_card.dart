import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'doubler_scaffold.dart';

/// Card used for every grouped block in the app.
class DoublerCard extends StatelessWidget {
  const DoublerCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to [AppSpacing.card].
  final EdgeInsetsGeometry? padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DoublerCardSurface(
      onTap: onTap,
      selected: selected,
      padding: padding ?? AppSpacing.card,
      child: child,
    );
  }
}
