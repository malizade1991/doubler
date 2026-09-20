import 'dart:io';

import '../../core/errors/app_failure.dart';

typedef GeminiGet = Future<int> Function(Uri uri);

class GeminiConnectionTester {
  GeminiConnectionTester({GeminiGet? get}) : _get = get ?? defaultGet;

  static const modelsPath =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final GeminiGet _get;

  /// Tests the key without logging it. [key] is only appended to the URI.
  Future<void> testKey(String key) async {
    final uri = Uri.parse('$modelsPath?key=${Uri.encodeQueryComponent(key)}');
    final status = await _get(uri);
    if (status == 200) {
      return;
    }
    if (status == 400 || status == 401 || status == 403) {
      throw const AppFailure(code: 'keyInvalid');
    }
    if (status == 429) {
      throw const AppFailure(code: 'quotaExceeded');
    }
    throw AppFailure(code: 'geminiUnavailable', message: 'HTTP $status');
  }

  static Future<int> defaultGet(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    } on SocketException {
      throw const AppFailure(code: 'geminiUnavailable');
    } finally {
      client.close(force: true);
    }
  }
}
