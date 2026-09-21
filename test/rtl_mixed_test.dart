import 'package:doubler/app.dart';
import 'package:doubler/core/l10n/locale_controller.dart';
import 'package:doubler/core/routing/app_routes.dart';
import 'package:doubler/shared/widgets/mixed_direction_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/doubler_bindings.dart';

void main() {
  setUp(() => mockDoublerStoreChannel());

  testWidgets('mixed Persian English numbers URL render', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MixedDirectionText(text: MixedDirectionText.mixedSample),
          ),
        ),
      ),
    );
    expect(find.textContaining('فارسی'), findsOneWidget);
    expect(find.textContaining('English'), findsOneWidget);
    expect(find.textContaining('123'), findsOneWidget);
    expect(find.textContaining('https://doubler.app'), findsOneWidget);
  });

  testWidgets('switching UI locale to English flips LTR', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DoublerApp()),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );

    final container = ProviderScope.containerOf(tester.element(find.byType(DoublerApp)));
    container.read(localeProvider.notifier).setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );

    // Let SplashScreen's navigation timer fire so no timer outlives the tree.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  test('language route constant exists', () {
    expect(AppRoutes.languageSelection, '/languages');
  });
}
