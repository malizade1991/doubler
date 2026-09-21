/// One Live API model option offered in Settings → Gemini.
class GeminiLiveModel {
  const GeminiLiveModel({
    required this.id,
    required this.label,
    this.note,
  });

  /// Sent to the API as `models/{id}`.
  final String id;

  /// Shown in the UI (product name, not a localised string).
  final String label;

  final String? note;

  String get resourceName => 'models/$id';
}

abstract final class GeminiConfig {
  static const wsHost = 'generativelanguage.googleapis.com';
  static const wsPath =
      '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  /// Google moved key auth here: standard (`AIza…`) and auth (`AQ…`) keys are
  /// both sent in this header for REST. The Live WebSocket still documents the
  /// `?key=` query parameter, so DOUBLER sends both — a client that would be
  /// rejected by one scheme succeeds through the other.
  static const apiKeyHeader = 'x-goog-api-key';

  /// Where users mint a key. Shown (never auto-opened; no browser dependency).
  static const keyConsoleUrl = 'https://aistudio.google.com/apikey';

  /// Continuous speech-to-speech translator. This is the dubbing default:
  /// `gemini-3.8-live` is a conversational agent and waits for a turn, so a
  /// YouTube video never gets a running translation.
  /// `gemini-2.5-flash-native-audio-preview-*` is retired.
  static const translateModel = 'gemini-3.5-live-translate-preview';

  /// Conversational fallback if the translate model is not enabled for the key.
  static const agentModel = 'gemini-3.8-live';

  static const liveModel = translateModel;

  static const List<GeminiLiveModel> liveModels = [
    GeminiLiveModel(
      id: translateModel,
      label: 'Gemini Live Translate',
      note: 'Continuous dubbing · YouTube',
    ),
    GeminiLiveModel(
      id: agentModel,
      label: 'Gemini 3.8 Live',
      note: 'Conversational fallback',
    ),
    GeminiLiveModel(
      id: 'gemini-3.8-live-extended-thinking',
      label: 'Gemini 3.8 Live · Thinking',
      note: 'Slower, better wording',
    ),
    GeminiLiveModel(
      id: 'gemini-3.1-flash-live-preview',
      label: 'Gemini 3.1 Flash Live',
      note: 'Older preview · fallback',
    ),
  ];

  static const defaultVoice = 'Kore';

  static const List<String> voices = [
    'Kore',
    'Puck',
    'Charon',
    'Fenrir',
    'Aoede',
    'Leda',
    'Orus',
    'Zephyr',
  ];

  /// The model resource name for [modelId], always a known-good one.
  static String modelResource(String? modelId) {
    for (final model in liveModels) {
      if (model.id == modelId) {
        return model.resourceName;
      }
    }
    return 'models/$liveModel';
  }

  static bool isKnownModel(String? modelId) {
    return liveModels.any((m) => m.id == modelId);
  }

  /// Live Translate is a pipeline, not a chatbot. Setup must not include a
  /// system instruction or a voice config — both are hard errors on that model.
  static bool isTranslateModel(String? modelId) {
    final id = (modelId == null || modelId.isEmpty) ? liveModel : modelId;
    return id.contains('translate');
  }

  static Uri liveUri(String apiKey) {
    return Uri(
      scheme: 'wss',
      host: wsHost,
      path: wsPath,
      queryParameters: {'key': apiKey},
    );
  }

  /// Headers for the Live handshake. Never logged.
  static Map<String, String> authHeaders(String apiKey) {
    return {apiKeyHeader: apiKey};
  }

  /// REST endpoint used to verify a key without spending generation quota.
  /// [keyInQuery] is only set for the legacy `?key=` retry path.
  static Uri modelsUri({String? keyInQuery}) {
    return Uri(
      scheme: 'https',
      host: wsHost,
      path: '/v1beta/models',
      queryParameters: keyInQuery == null ? null : {'key': keyInQuery},
    );
  }

  /// Safe for logs — never includes the API key.
  static String redactedUri() => 'wss://$wsHost$wsPath?key=REDACTED';
}
