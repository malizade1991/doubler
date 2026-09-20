import 'package:flutter/widgets.dart';

import '../../domain/models/language_catalog.dart';
import 'l10n_tables.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static List<Locale> get supportedLocales => LanguageCatalog.uiLanguageCodes
      .map((code) => Locale(code))
      .toList(growable: false);

  static AppLocalizations of(BuildContext context) {
    final loaded = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return loaded ?? AppLocalizations(const Locale('fa'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String key) {
    final code = locale.languageCode;
    final table = kL10nTables[code] ?? kL10nTables['fa']!;
    return table[key] ?? kL10nTables['fa']![key] ?? key;
  }

  String get appName => _t('appName');
  String get appNameLatin => _t('appNameLatin');
  String get tagline => _t('tagline');
  String get startLiveDubbing => _t('startLiveDubbing');
  String get liveTranslation => _t('liveTranslation');
  String get liveSubtitles => _t('liveSubtitles');
  String get conversation => _t('conversation');
  String get history => _t('history');
  String get settings => _t('settings');
  String get about => _t('about');
  String get privacy => _t('privacy');
  String get help => _t('help');
  String get apiKeySetup => _t('apiKeySetup');
  String get onboarding => _t('onboarding');
  String get languageSelection => _t('languageSelection');
  String get audioControls => _t('audioControls');
  String get liveTranscript => _t('liveTranscript');
  String get exportTranscript => _t('exportTranscript');
  String get geminiConfig => _t('geminiConfig');
  String get shellPlaceholder => _t('shellPlaceholder');
  String get uiLanguage => _t('uiLanguage');
  String get sourceLanguage => _t('sourceLanguage');
  String get targetLanguage => _t('targetLanguage');
  String get autoDetect => _t('autoDetect');
  String get mixedSampleLabel => _t('mixedSampleLabel');
  String get mixedSample => _t('mixedSample');
  String get onboardingWhat => _t('onboardingWhat');
  String get onboardingWhyKey => _t('onboardingWhyKey');
  String get onboardingHowKey => _t('onboardingHowKey');
  String get onboardingWherePaste => _t('onboardingWherePaste');
  String get onboardingPrivacy => _t('onboardingPrivacy');
  String get onboardingDirectGoogle => _t('onboardingDirectGoogle');
  String get next => _t('next');
  String get back => _t('back');
  String get saveKey => _t('saveKey');
  String get deleteKey => _t('deleteKey');
  String get testConnection => _t('testConnection');
  String get liveRequiresKey => _t('liveRequiresKey');
  String get byokExplainer => _t('byokExplainer');
  String get privacyBody => _t('privacyBody');
  String get keyStatusConfigured => _t('keyStatusConfigured');
  String get keyStatusMissing => _t('keyStatusMissing');
  String get officialKeyUrl => _t('officialKeyUrl');
  String get showKey => _t('showKey');
  String get hideKey => _t('hideKey');
  String get keyHint => _t('keyHint');
  String get connecting => _t('connecting');
  String get live => _t('live');
  String get disconnected => _t('disconnected');
  String get startSession => _t('startSession');
  String get stopSession => _t('stopSession');
  String get micDenied => _t('micDenied');
  String get listening => _t('listening');
  String get translating => _t('translating');
  String get speaking => _t('speaking');
  String get tone => _t('tone');
  String get toneCasual => _t('toneCasual');
  String get toneNatural => _t('toneNatural');
  String get toneFormal => _t('toneFormal');
  String get toneProfessional => _t('toneProfessional');
  String get latency => _t('latency');
  String get latencyGood => _t('latencyGood');
  String get latencyFair => _t('latencyFair');
  String get latencyPoor => _t('latencyPoor');
  String get subtitles => _t('subtitles');
  String get fontSize => _t('fontSize');
  String get textColor => _t('textColor');
  String get background => _t('background');
  String get position => _t('position');
  String get positionTop => _t('positionTop');
  String get positionCenter => _t('positionCenter');
  String get positionBottom => _t('positionBottom');
  String get originalVolume => _t('originalVolume');
  String get dubbedVolume => _t('dubbedVolume');
  String get smartDucking => _t('smartDucking');
  String get micModeMixNote => _t('micModeMixNote');
  String get copy => _t('copy');
  String get copied => _t('copied');
  String get share => _t('share');
  String get delete => _t('delete');
  String get emptyHistory => _t('emptyHistory');
  String get duration => _t('duration');
  String get bilingual => _t('bilingual');
  String get exportTxt => _t('exportTxt');
  String get exportSrt => _t('exportSrt');
  String get exportJson => _t('exportJson');
  String get appearance => _t('appearance');
  String get themeSystem => _t('themeSystem');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get voice => _t('voice');
  String get performance => _t('performance');
  String get perfLow => _t('perfLow');
  String get perfBalanced => _t('perfBalanced');
  String get perfQuality => _t('perfQuality');
  String get clearHistory => _t('clearHistory');
  String get clearAllData => _t('clearAllData');
  String get aboutBody => _t('aboutBody');
  String get offlineNote => _t('offlineNote');

  String message(String? code) {
    if (code == null || code.isEmpty) {
      return '';
    }
    return _t(code);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      LanguageCatalog.uiLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
