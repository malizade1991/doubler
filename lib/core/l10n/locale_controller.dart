import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/performance_mode.dart';
import '../../domain/models/subtitle_style.dart';
import '../../domain/models/translation_tone.dart';

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

final voiceIdProvider = StateProvider<String>((ref) => 'Kore');

final performanceModeProvider =
    StateProvider<PerformanceMode>((ref) => PerformanceMode.balanced);

const geminiVoices = <String>['Kore', 'Puck', 'Charon', 'Fenrir', 'Aoede'];
