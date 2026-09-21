import 'package:flutter/material.dart';

/// Renders mixed Persian/English/numbers/URLs without blindly mirroring
/// glyphs: the surrounding paragraph direction wins, embedded runs keep theirs.
class MixedDirectionText extends StatelessWidget {
  const MixedDirectionText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.selectable = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool selectable;

  static const mixedSample = 'فارسی + English + 123 + https://doubler.app';

  @override
  Widget build(BuildContext context) {
    if (selectable) {
      return SelectableText(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        textWidthBasis: TextWidthBasis.parent,
      );
    }
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textWidthBasis: TextWidthBasis.parent,
    );
  }
}
