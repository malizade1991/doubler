abstract final class GeminiErrorMapper {
  static String fromCloseCode(int? code, String? reason) {
    final r = (reason ?? '').toLowerCase();
    if (r.contains('quota') || r.contains('resource exhausted') || code == 1008) {
      return 'quotaExceeded';
    }
    if (r.contains('api key') ||
        r.contains('invalid') ||
        r.contains('permission') ||
        code == 4003 ||
        code == 1008) {
      return 'keyInvalid';
    }
    if (r.contains('model') && r.contains('not')) {
      return 'unsupportedModel';
    }
    if (code == 1006 || code == 1011) {
      return 'geminiUnavailable';
    }
    if (code == 1000) {
      return 'disconnected';
    }
    return 'geminiUnavailable';
  }
}
