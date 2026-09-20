import 'language.dart';

/// Translation pair catalog (not UI copy). Widgets must consume this list.
abstract final class LanguageCatalog {
  static const Language auto = Language(
    code: 'auto',
    nativeName: 'Auto',
    flag: '🌐',
    flow: TextFlow.ltr,
    supportedAsOutput: false,
  );

  static const List<Language> all = [
    auto,
    Language(code: 'fa-IR', nativeName: 'فارسی', flag: '🇮🇷', flow: TextFlow.rtl),
    Language(code: 'en-US', nativeName: 'English', flag: '🇺🇸', flow: TextFlow.ltr),
    Language(code: 'ar-SA', nativeName: 'العربية', flag: '🇸🇦', flow: TextFlow.rtl),
    Language(code: 'ru-RU', nativeName: 'Русский', flag: '🇷🇺', flow: TextFlow.ltr),
    Language(code: 'zh-CN', nativeName: '中文', flag: '🇨🇳', flow: TextFlow.ltr),
    Language(code: 'tr-TR', nativeName: 'Türkçe', flag: '🇹🇷', flow: TextFlow.ltr),
    Language(code: 'fr-FR', nativeName: 'Français', flag: '🇫🇷', flow: TextFlow.ltr),
    Language(code: 'de-DE', nativeName: 'Deutsch', flag: '🇩🇪', flow: TextFlow.ltr),
    Language(code: 'es-ES', nativeName: 'Español', flag: '🇪🇸', flow: TextFlow.ltr),
    Language(code: 'it-IT', nativeName: 'Italiano', flag: '🇮🇹', flow: TextFlow.ltr),
    Language(code: 'pt-BR', nativeName: 'Português', flag: '🇧🇷', flow: TextFlow.ltr),
    Language(code: 'ja-JP', nativeName: '日本語', flag: '🇯🇵', flow: TextFlow.ltr),
    Language(code: 'ko-KR', nativeName: '한국어', flag: '🇰🇷', flow: TextFlow.ltr),
    Language(code: 'hi-IN', nativeName: 'हिन्दी', flag: '🇮🇳', flow: TextFlow.ltr),
    Language(code: 'he-IL', nativeName: 'עברית', flag: '🇮🇱', flow: TextFlow.rtl),
    Language(code: 'nl-NL', nativeName: 'Nederlands', flag: '🇳🇱', flow: TextFlow.ltr),
    Language(code: 'pl-PL', nativeName: 'Polski', flag: '🇵🇱', flow: TextFlow.ltr),
    Language(code: 'uk-UA', nativeName: 'Українська', flag: '🇺🇦', flow: TextFlow.ltr),
    Language(code: 'vi-VN', nativeName: 'Tiếng Việt', flag: '🇻🇳', flow: TextFlow.ltr),
    Language(code: 'id-ID', nativeName: 'Bahasa Indonesia', flag: '🇮🇩', flow: TextFlow.ltr),
    Language(code: 'th-TH', nativeName: 'ไทย', flag: '🇹🇭', flow: TextFlow.ltr),
    Language(code: 'sv-SE', nativeName: 'Svenska', flag: '🇸🇪', flow: TextFlow.ltr),
  ];

  static Language byCode(String code) {
    return all.firstWhere(
      (l) => l.code == code || l.languageCode == code,
      orElse: () => all.firstWhere((l) => l.code == 'en-US'),
    );
  }

  static List<Language> get inputs =>
      all.where((l) => l.supportedAsInput).toList();

  static List<Language> get outputs =>
      all.where((l) => l.supportedAsOutput).toList();

  /// UI locales required by PRODUCT_SPEC.
  static const List<String> uiLanguageCodes = [
    'fa',
    'en',
    'ru',
    'ar',
    'zh',
    'tr',
    'fr',
    'de',
    'es',
    'it',
    'pt',
    'ja',
    'ko',
  ];
}
