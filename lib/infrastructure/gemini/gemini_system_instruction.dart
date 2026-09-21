import '../../domain/models/translation_tone.dart';
import '../../domain/providers/translation_provider.dart';

abstract final class GeminiSystemInstruction {
  static String build(SessionConfig config) {
    final source = config.sourceLanguage == 'auto'
        ? 'the detected spoken language'
        : config.sourceLanguage;
    final tone = _toneGuide(config.tone);
    return '''
You are DOUBLER, a real-time speech translator for audio playing in another app, such as a YouTube video.
Translate spoken $source into ${config.targetLanguage} only, continuously, as speech arrives.
Do not wait to be asked. Do not wait for a question.
Tone: ${config.tone}. $tone
Do not chat, explain, or add commentary.
Speak only the translation of what you hear.
If the input is already ${config.targetLanguage}, stay silent.
Never reply as an assistant; never ask questions.
''';
  }

  static String _toneGuide(String tone) {
    return switch (tone) {
      'casual' => 'Use everyday spoken language.',
      'formal' => 'Use polite, careful wording.',
      'professional' => 'Use precise, business-like wording.',
      _ => 'Use natural conversational wording.',
    };
  }

  static TranslationTone parseTone(String raw) {
    return TranslationTone.values.firstWhere(
      (t) => t.id == raw,
      orElse: () => TranslationTone.natural,
    );
  }
}
