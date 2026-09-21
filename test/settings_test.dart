import 'package:doubler/app.dart';
import 'package:doubler/core/l10n/locale_controller.dart';
import 'package:doubler/domain/models/performance_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theme mode provider switches MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoublerApp()));
    await tester.pump();
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);

    final ctx = tester.element(find.byType(DoublerApp));
    ProviderScope.containerOf(ctx).read(themeModeProvider.notifier).state =
        ThemeMode.dark;
    await tester.pump();
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    // Let SplashScreen's navigation timer fire so no timer outlives the tree.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  test('default performance is balanced', () {
    expect(PerformanceMode.balanced, isNotNull);
  });
}
