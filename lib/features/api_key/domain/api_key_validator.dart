/// Shapes of Google Gemini API keys that DOUBLER recognises.
///
/// Google replaced the old `AIza…` "standard" keys with `AQ…` "authorization"
/// (auth) keys. Both are accepted here; the *kind* only drives UI hints, it
/// never blocks a save. See GEMINI_INTEGRATION.md → "Key formats".
enum ApiKeyKind {
  /// New key issued by AI Studio (`AQ.` prefix, may contain dots).
  authKey,

  /// Legacy `AIza…` standard key. Google rejects unrestricted ones since 2026.
  standardKey,

  /// Anything else that still looks like a key (custom Cloud key, longer form).
  unknown,
}

class ApiKeyValidation {
  const ApiKeyValidation._({
    required this.isValid,
    this.code,
    this.kind = ApiKeyKind.unknown,
    this.normalized = '',
    this.warningCode,
  });

  final bool isValid;

  /// l10n key of the failure, when [isValid] is false.
  final String? code;

  final ApiKeyKind kind;

  /// Cleaned value that should be persisted (quotes/whitespace removed).
  final String normalized;

  /// Non-blocking l10n key shown next to a successful save.
  final String? warningCode;

  bool get isAuthKey => kind == ApiKeyKind.authKey;

  static const empty = ApiKeyValidation._(isValid: false, code: 'keyEmpty');
  static const tooShort = ApiKeyValidation._(isValid: false, code: 'keyTooShort');
  static const invalidFormat =
      ApiKeyValidation._(isValid: false, code: 'keyInvalid');

  static ApiKeyValidation accepted(
    String normalized,
    ApiKeyKind kind,
    String? warningCode,
  ) {
    return ApiKeyValidation._(
      isValid: true,
      kind: kind,
      normalized: normalized,
      warningCode: warningCode,
    );
  }
}

abstract final class ApiKeyValidator {
  /// Shortest key Google has ever shipped (older 20-char test keys included).
  static const minLength = 20;

  /// Legacy standard keys: `AIza` + 35 base64-ish characters.
  static final RegExp _standardKey = RegExp(r'^AIza[0-9A-Za-z_\-]{20,64}$');

  /// New auth keys: `AQ` + optional dot-separated segments.
  static final RegExp _authKey = RegExp(r'^AQ[.]?[0-9A-Za-z_\-]{8,}$');

  /// Allowed payload characters: base64url + the dots used by `AQ.` keys.
  static final RegExp _allowedChars = RegExp(r'^[0-9A-Za-z_\-.]+$');

  /// Labels people copy along with the key from docs or dashboards. A key can
  /// never contain `key=` (no `=` in the alphabet), so matching anywhere is safe.
  static final RegExp _labelPrefix =
      RegExp(r'(?:x[-\s]?goog[-\s]?api[-\s]?key|api[-\s]?key|key)\s*[:=]\s*',
          caseSensitive: false);

  /// Zero-width / no-break / bidi-control characters that survive a paste out
  /// of a browser or a chat app.
  static final RegExp _invisible = RegExp(
    r'[\u00A0\u2000-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF]',
  );

  static ApiKeyValidation validate(String raw) {
    final key = sanitize(raw);
    if (key.isEmpty) {
      return ApiKeyValidation.empty;
    }
    // A key is one opaque token; an interior space means the wrong thing was
    // pasted (a sentence, two keys, a URL with a query string…).
    if (key.contains(RegExp(r'\s'))) {
      return ApiKeyValidation.invalidFormat;
    }
    if (key.length < minLength) {
      return ApiKeyValidation.tooShort;
    }
    if (!_allowedChars.hasMatch(key)) {
      return ApiKeyValidation.invalidFormat;
    }
    if (_standardKey.hasMatch(key) || key.startsWith('AIza')) {
      return ApiKeyValidation.accepted(
        key,
        ApiKeyKind.standardKey,
        'keyWarningLegacy',
      );
    }
    if (_authKey.hasMatch(key)) {
      return ApiKeyValidation.accepted(key, ApiKeyKind.authKey, null);
    }
    // Unknown shape is still saved: Google's answer beats our guess.
    return ApiKeyValidation.accepted(key, ApiKeyKind.unknown, 'keyWarningShape');
  }

  /// Turns a paste into the bare token: strips labels, quotes, wrapping
  /// punctuation, invisible Unicode marks and the newlines soft-wrapped keys
  /// pick up inside a multiline field.
  static String sanitize(String raw) {
    var value = raw.replaceAll(_invisible, '');
    // Pasting "…apikey?key=AIza…" is common; keep the token after `key=`.
    final queryIndex = value.indexOf('key=');
    if (queryIndex >= 0) {
      value = value.substring(queryIndex + 4);
    }
    value = value.trim();
    for (final match in _labelPrefix.allMatches(value)) {
      value = value.substring(match.end).trim();
    }
    final lines = value
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.length > 1) {
      value = lines.reduce((a, b) => b.length > a.length ? b : a);
    } else {
      value = lines.isEmpty ? '' : lines.first;
    }
    return _stripWrapping(value);
  }

  static String _stripWrapping(String value) {
    var out = value;
    const pairs = {
      '"': '"',
      "'": "'",
      '`': '`',
      '<': '>',
      '[': ']',
      '(': ')',
    };
    var changed = true;
    while (changed && out.length >= 2) {
      changed = false;
      for (final entry in pairs.entries) {
        if (out.startsWith(entry.key) && out.endsWith(entry.value)) {
          out = out.substring(1, out.length - 1).trim();
          changed = true;
        }
      }
      while (out.endsWith(',') || out.endsWith(';') || out.endsWith('.')) {
        out = out.substring(0, out.length - 1).trimRight();
        changed = true;
      }
    }
    return out;
  }

  static ApiKeyKind kindOf(String raw) {
    final key = sanitize(raw);
    if (_standardKey.hasMatch(key) || key.startsWith('AIza')) {
      return ApiKeyKind.standardKey;
    }
    if (_authKey.hasMatch(key)) {
      return ApiKeyKind.authKey;
    }
    return ApiKeyKind.unknown;
  }

  static String mask(String key) {
    if (key.length <= 8) {
      return '••••';
    }
    return '${key.substring(0, 4)}••••${key.substring(key.length - 3)}';
  }
}
