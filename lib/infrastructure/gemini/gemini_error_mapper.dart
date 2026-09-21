import 'gemini_connection_tester.dart';

/// Maps Gemini transport failures onto l10n message codes.
///
/// The Live API reports auth problems in three shapes: a WebSocket close code
/// with a reason, a `{"error": {...}}` frame, or a rejected HTTP upgrade
/// (handshake). All three must land on a message that tells the user whether
/// their *key* is at fault or the *network* is.
abstract final class GeminiErrorMapper {
  static String fromCloseCode(int? code, String? reason) {
    final r = (reason ?? '').toLowerCase();
    final overQuota = r.contains('quota') ||
        r.contains('resource exhausted') ||
        r.contains('rate limit');
    // "API key has exceeded its quota" must not be reported as a bad key.
    if (overQuota) {
      return 'quotaExceeded';
    }
    if (_looksLikeKeyProblem(r) || r.contains('invalid')) {
      return 'keyInvalid';
    }
    if (r.contains('model') &&
        (r.contains('not found') ||
            r.contains('not exist') ||
            r.contains('unsupported') ||
            r.contains('deprecated'))) {
      return 'unsupportedModel';
    }
    if (code == 1000) {
      return 'disconnected';
    }
    if (code == 1008 || code == 4003) {
      return 'keyInvalid';
    }
    if (code == 1006 || code == 1011) {
      return 'geminiUnavailable';
    }
    return 'geminiUnavailable';
  }

  /// A failed `GET /v1beta/models` upgrade is the usual way a bad key shows up
  /// when opening the Live socket.
  static String fromHttpStatus(int status, {String? key, String? body}) {
    final lowered = (body ?? '').toLowerCase();
    if (lowered.contains('api key not valid') ||
        lowered.contains('invalid api key') ||
        lowered.contains('permission_denied') ||
        lowered.contains('unauthenticated') ||
        lowered.contains('access_token_type_unsupported')) {
      return 'keyInvalid';
    }
    if (lowered.contains('quota') || lowered.contains('resource_exhausted')) {
      return 'quotaExceeded';
    }
    return GeminiConnectionTester.failureCodeForStatus(status, key: key);
  }

  static bool _looksLikeKeyProblem(String reason) {
    return reason.contains('api key') ||
        reason.contains('apikey') ||
        reason.contains('unauthenticated') ||
        reason.contains('permission denied') ||
        reason.contains('access denied');
  }
}
