import 'package:flutter/material.dart';

/// Persian-first type. Bundle Vazirmatn under assets/fonts when available;
/// until then, platform Arabic-script fallbacks are used.
abstract final class AppTypography {
  static const String primaryFont = 'Vazirmatn';

  static const List<String> fallbacks = [
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
    'Tahoma',
    'sans-serif',
  ];

  static TextTheme textTheme(ColorScheme scheme) {
    TextStyle base(double size, FontWeight weight, {double? height}) {
      return TextStyle(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbacks,
        fontSize: size,
        fontWeight: weight,
        height: height ?? 1.45,
        color: scheme.onSurface,
        letterSpacing: 0,
      );
    }

    return TextTheme(
      displayLarge: base(40, FontWeight.w700, height: 1.2),
      displayMedium: base(32, FontWeight.w700, height: 1.25),
      headlineLarge: base(28, FontWeight.w700, height: 1.3),
      headlineMedium: base(24, FontWeight.w600, height: 1.3),
      headlineSmall: base(20, FontWeight.w600),
      titleLarge: base(18, FontWeight.w600),
      titleMedium: base(16, FontWeight.w600),
      titleSmall: base(14, FontWeight.w600),
      bodyLarge: base(16, FontWeight.w400),
      bodyMedium: base(14, FontWeight.w400),
      bodySmall: base(12, FontWeight.w400),
      labelLarge: base(14, FontWeight.w600),
      labelMedium: base(12, FontWeight.w600),
      labelSmall: base(11, FontWeight.w500),
    );
  }
}
