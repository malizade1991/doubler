import 'dart:async';
import 'dart:io';

import '../../core/errors/app_failure.dart';
import 'gemini_config.dart';

/// Performs a `GET` and returns the status code. Injected in tests.
typedef GeminiGet = Future<int> Function(Uri uri, Map<String, String> headers);

/// Verifies a Gemini API key against the model list endpoint.
///
/// Google now requires the `x-goog-api-key` header: `AQ…` auth keys answer
/// 404 on `?key=`, and unrestricted `AIza…` standard keys are rejected
/// outright. So the header is tried first and the query parameter only as a
/// legacy fallback.
class GeminiConnectionTester {
  GeminiConnectionTester({
    GeminiGet? get,
    this.timeout = const Duration(seconds: 15),
  }) : _get = get ?? defaultGet;

  final GeminiGet _get;
  final Duration timeout;

  /// Returns normally when the key works. Throws [AppFailure] with an l10n
  /// code otherwise — including [code] `connectionOkQuota` for a valid key
  /// whose quota is spent.
  Future<void> testKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw const AppFailure(code: 'keyEmpty');
    }

    final headerStatus = await _status(
      GeminiConfig.modelsUri(),
      GeminiConfig.authHeaders(trimmed),
    );
    if (headerStatus == 200) {
      return;
    }
    if (headerStatus == 429) {
      // Authenticated fine; only the quota is exhausted.
      throw const AppFailure(code: 'connectionOkQuota', message: 'HTTP 429');
    }

    if (!_isAuthRejection(headerStatus)) {
      throw AppFailure(
        code: failureCodeForStatus(headerStatus, key: trimmed),
        message: 'HTTP $headerStatus',
      );
    }

    // Legacy path: a *restricted* standard key may still accept `?key=`.
    final queryStatus = await _status(
      GeminiConfig.modelsUri(keyInQuery: trimmed),
      const <String, String>{},
    );
    if (queryStatus == 200) {
      return;
    }
    if (queryStatus == 429) {
      throw const AppFailure(code: 'connectionOkQuota', message: 'HTTP 429');
    }
    throw AppFailure(
      code: failureCodeForStatus(queryStatus, key: trimmed),
      message: 'HTTP $headerStatus/$queryStatus',
    );
  }

  Future<int> _status(Uri uri, Map<String, String> headers) async {
    try {
      return await _get(uri, headers).timeout(timeout);
    } on AppFailure {
      rethrow;
    } on FormatException {
      throw const AppFailure(code: 'keyInvalid');
    } on TimeoutException {
      throw const AppFailure(code: 'connectionTimeout');
    } on Object {
      throw const AppFailure(code: 'networkUnavailable');
    }
  }

  static bool _isAuthRejection(int status) {
    return status == 400 || status == 401 || status == 403 || status == 404;
  }

  /// Maps an HTTP status (plus the key shape, when useful) to an l10n code.
  static String failureCodeForStatus(int status, {String? key}) {
    switch (status) {
      case 200:
        return 'connectionOk';
      case 429:
        return 'quotaExceeded';
      case 400:
      case 401:
      case 403:
      case 404:
        if (key != null && key.startsWith('AIza')) {
          return 'keyLegacyRejected';
        }
        return 'keyInvalid';
      default:
        return 'geminiUnavailable';
    }
  }

  /// Status code only — the key never ends up in a log line.
  static Future<int> defaultGet(Uri uri, Map<String, String> headers) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach((String name, String value) {
        request.headers.set(name, value);
      });
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    } on SocketException {
      throw const AppFailure(code: 'networkUnavailable');
    } finally {
      client.close(force: true);
    }
  }
}
