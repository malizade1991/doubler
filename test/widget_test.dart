import 'package:doubler/app.dart';
import 'package:doubler/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into splash then onboarding without a key', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DoublerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('DOUBLER'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations(const Locale('fa'));
    expect(find.text(l10n.onboarding), findsWidgets);
    expect(find.text(l10n.onboardingWhat), findsOneWidget);
  });
}
