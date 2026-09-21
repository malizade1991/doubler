import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_controller.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class DoublerApp extends ConsumerWidget {
  const DoublerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'DOUBLER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (proposed, supported) {
        if (proposed == null) {
          return const Locale('fa');
        }
        for (final locale in supported) {
          if (locale.languageCode == proposed.languageCode) {
            return locale;
          }
        }
        return const Locale('fa');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      // Persian text at 2× system scale breaks every layout in the app; clamp
      // it so the live screen stays usable for low-vision users.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.35,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
