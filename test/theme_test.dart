import 'package:doubler/core/theme/app_colors.dart';
import 'package:doubler/core/theme/app_spacing.dart';
import 'package:doubler/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes use DOUBLER color schemes', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, AppColors.signal);
    expect(dark.useMaterial3, isTrue);
    expect(AppSpacing.lg, 24);
  });
}
