import 'package:flutter/widgets.dart';

enum TextFlow { ltr, rtl }

class Language {
  const Language({
    required this.code,
    required this.nativeName,
    required this.flag,
    required this.flow,
    this.supportedAsInput = true,
    this.supportedAsOutput = true,
  });

  /// BCP-47, e.g. `fa-IR`.
  final String code;
  final String nativeName;
  final String flag;
  final TextFlow flow;
  final bool supportedAsInput;
  final bool supportedAsOutput;

  String get languageCode => code.split('-').first;

  TextDirection get textDirection =>
      flow == TextFlow.rtl ? TextDirection.rtl : TextDirection.ltr;

  bool get isRtl => flow == TextFlow.rtl;
}
