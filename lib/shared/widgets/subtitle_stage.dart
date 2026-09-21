import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/subtitle_style.dart';
import 'mixed_direction_text.dart';

/// The live caption surface: bilingual-friendly text on a scrim that stays
/// readable over any background.
class SubtitleStage extends StatelessWidget {
  const SubtitleStage({
    super.key,
    required this.text,
    required this.style,
    this.placeholder = '—',
    this.maxLines = 4,
  });

  final String text;
  final SubtitleStyle style;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final line = text.trim().isEmpty ? placeholder : text.trim();
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: AppRadii.card,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: MixedDirectionText(
        text: line,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: style.fontSize,
          color: style.textColor,
          height: 1.35,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(color: Color(0x66000000), blurRadius: 8),
          ],
        ),
      ),
    );

    final alignment = switch (style.position) {
      SubtitlePosition.top => Alignment.topCenter,
      SubtitlePosition.center => Alignment.center,
      SubtitlePosition.bottom => Alignment.bottomCenter,
    };

    return Align(
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        // Keyed on the text so a new caption fades in instead of jumping.
        child: Container(
          key: ValueKey<String>(line),
          alignment: alignment,
          child: bubble,
        ),
      ),
    );
  }
}
