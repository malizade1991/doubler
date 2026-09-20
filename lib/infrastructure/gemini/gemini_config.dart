abstract final class GeminiConfig {
  static const wsHost = 'generativelanguage.googleapis.com';
  static const wsPath =
      '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  /// Override in one place if Google renames the Live model.
  static const liveModel = 'models/gemini-2.5-flash-native-audio-preview-12-2025';

  static const defaultVoice = 'Kore';

  static Uri liveUri(String apiKey) {
    return Uri(
      scheme: 'wss',
      host: wsHost,
      path: wsPath,
      queryParameters: {'key': apiKey},
    );
  }

  /// Safe for logs — never includes the API key.
  static String redactedUri() => 'wss://$wsHost$wsPath?key=REDACTED';
}
