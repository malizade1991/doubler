import 'package:flutter/material.dart';

/// DOUBLER visual identity: deep teal (signal) + amber (voice energy).
abstract final class AppColors {
  static const Color signal = Color(0xFF0E6B7A);
  static const Color signalDeep = Color(0xFF07343C);
  static const Color voice = Color(0xFFE8A838);
  static const Color mist = Color(0xFFF4F7F8);
  static const Color ink = Color(0xFF10181A);
  static const Color inkMuted = Color(0xFF5C6B70);
  static const Color surfaceDark = Color(0xFF0C1416);
  static const Color cardDark = Color(0xFF162225);
  static const Color danger = Color(0xFFC23B3B);
  static const Color success = Color(0xFF2A9D6E);
  static const Color warning = Color(0xFFD97706);
  static const Color live = Color(0xFF22C55E);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: signal,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD4EEF2),
      onPrimaryContainer: signalDeep,
      secondary: voice,
      onSecondary: ink,
      secondaryContainer: Color(0xFFFFE8C2),
      onSecondaryContainer: Color(0xFF3D2A08),
      tertiary: Color(0xFF3D5A80),
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: mist,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      outline: Color(0xFFC5D0D3),
      outlineVariant: Color(0xFFE2EAEC),
      inverseSurface: ink,
      onInverseSurface: mist,
      inversePrimary: Color(0xFF7ED4E0),
      surfaceTint: signal,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7ED4E0),
      onPrimary: signalDeep,
      primaryContainer: Color(0xFF0A4E58),
      onPrimaryContainer: Color(0xFFD4EEF2),
      secondary: voice,
      onSecondary: ink,
      secondaryContainer: Color(0xFF5A3E12),
      onSecondaryContainer: Color(0xFFFFE8C2),
      tertiary: Color(0xFF9BB4D4),
      onTertiary: Color(0xFF102033),
      error: Color(0xFFFF8A80),
      onError: Color(0xFF3B0A0A),
      surface: surfaceDark,
      onSurface: Color(0xFFE8F0F2),
      onSurfaceVariant: Color(0xFF9AADB2),
      outline: Color(0xFF3A4C50),
      outlineVariant: Color(0xFF243338),
      inverseSurface: mist,
      onInverseSurface: ink,
      inversePrimary: signal,
      surfaceTint: Color(0xFF7ED4E0),
    );
  }
}
