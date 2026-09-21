import 'package:doubler/features/dubbing/application/youtube_handoff.dart';
import 'package:doubler/infrastructure/gemini/gemini_live_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('YouTube opens once, only on the idle → live edge', () {
    expect(
      shouldOpenYouTube(
        wasLive: false,
        isLive: true,
        enabled: true,
        alreadyOpened: false,
      ),
      isTrue,
    );
    expect(
      shouldOpenYouTube(
        wasLive: true,
        isLive: true,
        enabled: true,
        alreadyOpened: false,
      ),
      isFalse,
    );
    expect(
      shouldOpenYouTube(
        wasLive: false,
        isLive: true,
        enabled: false,
        alreadyOpened: false,
      ),
      isFalse,
    );
    expect(
      shouldOpenYouTube(
        wasLive: false,
        isLive: true,
        enabled: true,
        alreadyOpened: true,
      ),
      isFalse,
    );
    expect(
      shouldOpenYouTube(
        wasLive: false,
        isLive: false,
        enabled: true,
        alreadyOpened: false,
      ),
      isFalse,
    );
  });

  test('translation language codes match the Live Translate catalog', () {
    expect(GeminiLiveMessages.translationLanguageCode('fa-IR'), 'fa');
    expect(GeminiLiveMessages.translationLanguageCode('en-US'), 'en');
    expect(GeminiLiveMessages.translationLanguageCode('zh-CN'), 'zh-Hans');
    expect(GeminiLiveMessages.translationLanguageCode('pt-BR'), 'pt-BR');
    expect(GeminiLiveMessages.translationLanguageCode('ar-SA'), 'ar');
  });

  test('setupComplete object, true, and snake_case all count', () {
    expect(GeminiLiveMessages.isSetupComplete({'setupComplete': <String, dynamic>{}}), isTrue);
    expect(GeminiLiveMessages.isSetupComplete({'setupComplete': true}), isTrue);
    expect(GeminiLiveMessages.isSetupComplete({'setup_complete': <String, dynamic>{}}), isTrue);
    expect(GeminiLiveMessages.isSetupComplete({'setupComplete': false}), isFalse);
    expect(GeminiLiveMessages.isSetupComplete({'serverContent': <String, dynamic>{}}), isFalse);
  });
}
