import 'package:flutter/material.dart';

/// Renders mixed Persian/English/numbers/URLs without blindly mirroring glyphs.
class MixedDirectionText extends StatelessWidget {
  const MixedDirectionText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  static const mixedSample = 'فارسی + English + 123 + https://doubler.app';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      textWidthBasis: TextWidthBasis.parent,
    );
  }
}
