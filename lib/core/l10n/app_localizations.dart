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
    final value = table[key];
    if (value != null) {
      return value;
    }
    // Partial locales (ru, ar, zh, …) fall back to English first: a Russian
    // user reading a Persian string is not a fallback, it is a bug.
    if (code != 'fa') {
      final english = kL10nTables['en']![key];
      if (english != null) {
        return english;
      }
    }
    return kL10nTables['fa']![key] ?? key;
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

  String get allDataCleared => _t('allDataCleared');
  String get appSection => _t('appSection');
  String get authHeaderLabel => _t('authHeaderLabel');
  String get bilingualHint => _t('bilingualHint');
  String get cancel => _t('cancel');
  String get clear => _t('clear');
  String get clearField => _t('clearField');
  String get colorAmber => _t('colorAmber');
  String get colorBlack => _t('colorBlack');
  String get colorDeepTeal => _t('colorDeepTeal');
  String get colorFrost => _t('colorFrost');
  String get colorInk => _t('colorInk');
  String get colorNone => _t('colorNone');
  String get colorTeal => _t('colorTeal');
  String get colorWhite => _t('colorWhite');
  String get confirm => _t('confirm');
  String get confirmClearAllBody => _t('confirmClearAllBody');
  String get confirmClearHistoryBody => _t('confirmClearHistoryBody');
  String get confirmDeleteKeyBody => _t('confirmDeleteKeyBody');
  String get confirmDeleteSessionBody => _t('confirmDeleteSessionBody');
  String get connectionLabel => _t('connectionLabel');
  String get connectionOk => _t('connectionOk');
  String get connectionOkQuota => _t('connectionOkQuota');
  String get connectionTimeout => _t('connectionTimeout');
  String get continueToHome => _t('continueToHome');
  String get data => _t('data');
  String get duckingOn => _t('duckingOn');
  String get endpointLabel => _t('endpointLabel');
  String get engineSummary => _t('engineSummary');
  String get exportEmpty => _t('exportEmpty');
  String get exportEmptyHint => _t('exportEmptyHint');
  String get exportFormat => _t('exportFormat');
  String get exportRefresh => _t('exportRefresh');
  String get exportSegments => _t('exportSegments');
  String get geminiConfigNote => _t('geminiConfigNote');
  String get headphonesNote => _t('headphonesNote');
  String get helpBackgroundBody => _t('helpBackgroundBody');
  String get helpBackgroundTitle => _t('helpBackgroundTitle');
  String get helpFeedbackBody => _t('helpFeedbackBody');
  String get helpFeedbackTitle => _t('helpFeedbackTitle');
  String get helpKeyBody => _t('helpKeyBody');
  String get helpKeyTitle => _t('helpKeyTitle');
  String get helpLanguageNote => _t('helpLanguageNote');
  String get helpNetworkBody => _t('helpNetworkBody');
  String get helpNetworkTitle => _t('helpNetworkTitle');
  String get helpSilenceBody => _t('helpSilenceBody');
  String get helpSilenceTitle => _t('helpSilenceTitle');
  String get historyCleared => _t('historyCleared');
  String get historyEmptyHint => _t('historyEmptyHint');
  String get historyMissingHint => _t('historyMissingHint');
  String get homeNeedsKeyHint => _t('homeNeedsKeyHint');
  String get homeReadyHint => _t('homeReadyHint');
  String get keyConsoleLabel => _t('keyConsoleLabel');
  String get keyDeleted => _t('keyDeleted');
  String get keyHowToTitle => _t('keyHowToTitle');
  String get keyKindAny => _t('keyKindAny');
  String get keyKindAuth => _t('keyKindAuth');
  String get keyLegacyRejected => _t('keyLegacyRejected');
  String get keyNeverLeaves => _t('keyNeverLeaves');
  String get keyPasteNote => _t('keyPasteNote');
  String get keySaved => _t('keySaved');
  String get keyStepOne => _t('keyStepOne');
  String get keyStepThree => _t('keyStepThree');
  String get keyStepTwo => _t('keyStepTwo');
  String get keyWarningLegacy => _t('keyWarningLegacy');
  String get keyWarningShape => _t('keyWarningShape');
  String get levels => _t('levels');
  String get mixingControls => _t('mixingControls');
  String get modelLabel => _t('modelLabel');
  String get muteMic => _t('muteMic');
  String get networkRequiredNote => _t('networkRequiredNote');
  String get networkUnavailable => _t('networkUnavailable');
  String get outputRouting => _t('outputRouting');
  String get outputRoutingNote => _t('outputRoutingNote');
  String get paste => _t('paste');
  String get previewEmpty => _t('previewEmpty');
  String get previewLabel => _t('previewLabel');
  String get privacyErase => _t('privacyErase');
  String get privacyFooter => _t('privacyFooter');
  String get privacyKey => _t('privacyKey');
  String get privacyMic => _t('privacyMic');
  String get privacyNoServer => _t('privacyNoServer');
  String get quickActions => _t('quickActions');
  String get session => _t('session');
  String get sessionCompleted => _t('sessionCompleted');
  String get sessionError => _t('sessionError');
  String get sessionIdle => _t('sessionIdle');
  String get sessionInterrupted => _t('sessionInterrupted');
  String get setupSection => _t('setupSection');
  String get skip => _t('skip');
  String get smartDuckingHint => _t('smartDuckingHint');
  String get subtitlePreview => _t('subtitlePreview');
  String get swapLanguages => _t('swapLanguages');
  String get transcriptEmpty => _t('transcriptEmpty');
  String get transcriptEmptyHint => _t('transcriptEmptyHint');
  String get transport => _t('transport');
  String get tryAgain => _t('tryAgain');
  String get uiLanguageHint => _t('uiLanguageHint');
  String get unmuteMic => _t('unmuteMic');
  String get unsupportedModel => _t('unsupportedModel');
  String get versionLabel => _t('versionLabel');

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
