import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/performance_mode.dart';
import '../../domain/models/subtitle_style.dart';
import '../../domain/models/translation_tone.dart';
import '../../infrastructure/gemini/gemini_config.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fa');

  void setLocale(Locale locale) => state = locale;
}

final sourceLanguageCodeProvider = StateProvider<String>((ref) => 'auto');
final targetLanguageCodeProvider = StateProvider<String>((ref) => 'fa-IR');
final translationToneProvider =
    StateProvider<TranslationTone>((ref) => TranslationTone.natural);

final subtitleStyleProvider =
    StateProvider<SubtitleStyle>((ref) => const SubtitleStyle());

final originalVolumeProvider = StateProvider<double>((ref) => 0.25);
final dubbedVolumeProvider = StateProvider<double>((ref) => 0.85);
final smartDuckingProvider = StateProvider<bool>((ref) => true);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final voiceIdProvider = StateProvider<String>((ref) => GeminiConfig.defaultVoice);

/// Live API model id used for new sessions. Kept in settings because Google
/// renames these; see GEMINI_INTEGRATION.md → "Models".
final geminiModelProvider =
    StateProvider<String>((ref) => GeminiConfig.liveModel);

final performanceModeProvider =
    StateProvider<PerformanceMode>((ref) => PerformanceMode.balanced);

const List<String> geminiVoices = GeminiConfig.voices;
