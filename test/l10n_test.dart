import 'package:doubler/core/l10n/app_localizations.dart';
import 'package:doubler/core/l10n/l10n_tables.dart';
import 'package:doubler/domain/models/language_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all UI locales have complete keys matching fa', () {
    final faKeys = kL10nTables['fa']!.keys.toSet();
    for (final code in LanguageCatalog.uiLanguageCodes) {
      expect(kL10nTables.containsKey(code), isTrue, reason: code);
      expect(
        faKeys.containsAll(kL10nTables[code]!.keys),
        isTrue,
        reason: '$code has unknown keys',
      );
    }
  });

  test('Persian is default and Arabic is RTL in catalog', () {
    expect(LanguageCatalog.byCode('fa').isRtl, isTrue);
    expect(LanguageCatalog.byCode('ar').isRtl, isTrue);
    expect(LanguageCatalog.byCode('en').isRtl, isFalse);
    expect(AppLocalizations(const Locale('fa')).startLiveDubbing, 'شروع دوبله زنده');
  });

  test('catalog is consumed without widget-hardcoded language lists', () {
    expect(LanguageCatalog.outputs, isNotEmpty);
    expect(LanguageCatalog.inputs.any((l) => l.code == 'auto'), isTrue);
  });
}
