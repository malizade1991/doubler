import 'dart:typed_data';

/// AI provider contract. UI depends only on this type.
abstract class TranslationProvider {
  Stream<ProviderEvent> connect(SessionConfig config);

  void sendAudio(Uint8List pcm16k);

  void updateConfig(SessionConfig patch);

  Future<void> disconnect();
}

class SessionConfig {
  const SessionConfig({
    required this.sourceLanguage,
    required this.targetLanguage,
    this.tone = 'natural',
    this.voiceId,
    this.apiKey,
    this.model,
  });

  final String sourceLanguage;
  final String targetLanguage;
  final String tone;
  final String? voiceId;

  /// Never logged. Passed only into the provider.
  final String? apiKey;

  /// Live API model id (e.g. `gemini-3.8-live`); null means provider default.
  final String? model;

  SessionConfig merge(SessionConfig patch) {
    return SessionConfig(
      sourceLanguage: patch.sourceLanguage,
      targetLanguage: patch.targetLanguage,
      tone: patch.tone,
      voiceId: patch.voiceId ?? voiceId,
      apiKey: patch.apiKey ?? apiKey,
      model: patch.model ?? model,
    );
  }
}

sealed class ProviderEvent {
  const ProviderEvent();
}

class ProviderConnected extends ProviderEvent {
  const ProviderConnected();
}

class ProviderDisconnected extends ProviderEvent {
  const ProviderDisconnected();
}

class ProviderError extends ProviderEvent {
  const ProviderError(this.code);
  final String code;
}

class ProviderAudioOut extends ProviderEvent {
  const ProviderAudioOut(this.pcm24k);
  final Uint8List pcm24k;
}

class ProviderTranscript extends ProviderEvent {
  const ProviderTranscript({
    required this.text,
    required this.isInput,
    this.isFinal = false,
  });

  final String text;
  final bool isInput;
  final bool isFinal;
}

class ProviderSpeaking extends ProviderEvent {
  const ProviderSpeaking(this.active);
  final bool active;
}

class ProviderResumed extends ProviderEvent {
  const ProviderResumed(this.handle);
  final String handle;
}
