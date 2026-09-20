import 'package:flutter/material.dart';

enum SubtitlePosition { top, center, bottom }

class SubtitleStyle {
  const SubtitleStyle({
    this.fontSize = 22,
    this.textColor = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0xCC07343C),
    this.position = SubtitlePosition.bottom,
  });

  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final SubtitlePosition position;

  SubtitleStyle copyWith({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    SubtitlePosition? position,
  }) {
    return SubtitleStyle(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      position: position ?? this.position,
    );
  }
}
