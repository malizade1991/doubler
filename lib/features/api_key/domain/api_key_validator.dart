class ApiKeyValidation {
  const ApiKeyValidation._(this.isValid, this.code);

  final bool isValid;
  final String? code;

  static const empty = ApiKeyValidation._(false, 'keyEmpty');
  static const tooShort = ApiKeyValidation._(false, 'keyTooShort');
  static const invalidFormat = ApiKeyValidation._(false, 'keyInvalid');
  static const ok = ApiKeyValidation._(true, null);
}

abstract final class ApiKeyValidator {
  static const minLength = 20;

  static ApiKeyValidation validate(String raw) {
    final key = raw.trim();
    if (key.isEmpty) {
      return ApiKeyValidation.empty;
    }
    if (key.contains(' ')) {
      return ApiKeyValidation.invalidFormat;
    }
    if (key.length < minLength) {
      return ApiKeyValidation.tooShort;
    }
    // Google AI Studio keys commonly start with AIza.
    if (!RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(key)) {
      return ApiKeyValidation.invalidFormat;
    }
    return ApiKeyValidation.ok;
  }

  static String mask(String key) {
    if (key.length <= 8) {
      return '••••';
    }
    return '${key.substring(0, 4)}••••${key.substring(key.length - 2)}';
  }
}
