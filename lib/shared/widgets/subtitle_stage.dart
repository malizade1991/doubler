import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/subtitle_style.dart';
import 'mixed_direction_text.dart';

class SubtitleStage extends StatelessWidget {
  const SubtitleStage({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final SubtitleStyle style;

  @override
  Widget build(BuildContext context) {
    final line = text.trim().isEmpty ? '—' : text;
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: AppRadii.card,
      ),
      child: MixedDirectionText(
        text: line,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: style.fontSize,
          color: style.textColor,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Align(
      alignment: switch (style.position) {
        SubtitlePosition.top => Alignment.topCenter,
        SubtitlePosition.center => Alignment.center,
        SubtitlePosition.bottom => Alignment.bottomCenter,
      },
      child: bubble,
    );
  }
}
