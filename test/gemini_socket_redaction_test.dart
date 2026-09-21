import 'dart:io';

import 'package:doubler/infrastructure/gemini/gemini_socket.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key is pasted by the user and then travels in the Live URL (`?key=…`)
/// *and* in the `x-goog-api-key` header, so any string `dart:io` hands the
/// classifier can embed it. Two properties have to hold: a token whose own
/// characters spell `401`/`429` must not decide the error code, and the key must
/// not survive into a message the user — or a log line — can see.
///
/// `describeError` only ever reports the HTTP status, so the assertions below
/// pin the classification side; the redaction unit tests in
/// `gemini_provider_test.dart` pin the scrubbing itself.
void main() {
  group('the key never decides the error code', () {
    test('a key that spells 401 in the URL is not "invalid key"', () {
      const error = WebSocketException(
        'Connection to wss://generativelanguage.googleapis.com/ws/'
        'BidiGenerateContent?key=AIzaSyD401QUOTAdecoys_0123456789 failed',
      );
      expect(IoGeminiSocket.statusCodeOf(error), isNull);
      expect(IoGeminiSocket.describeError(error), isNull);
      expect(IoGeminiSocket.classifyError(error), 'geminiUnavailable');
    });

    test('a key that spells 429 in the header is not "quota"', () {
      final error = Exception(
        'Handshake failed after x-goog-api-key: AQ.Ab8QN_429decoy_value',
      );
      expect(IoGeminiSocket.statusCodeOf(error), isNull);
      expect(IoGeminiSocket.classifyError(error), 'geminiUnavailable');
    });

    test('a bare token in a transport message is stripped as well', () {
      expect(
        IoGeminiSocket.statusCodeOf(
          const SocketException('Connection reset by peer AQ.Ab8QN_401decoy'),
        ),
        isNull,
      );
      expect(
        IoGeminiSocket.classifyError(
          const SocketException(
            'Connection reset by peer AIzaSyD401QUOTAdecoys_0123456789',
          ),
        ),
        'geminiUnavailable',
      );
      expect(
        IoGeminiSocket.classifyError(
          const SocketException('Connection reset by peer'),
        ),
        'geminiUnavailable',
      );
    });

    test('the real status still wins when the key shares the message', () {
      const error = WebSocketException(
        'Connection to wss://host/ws?key=AQ.Ab8QN_401decoy_value failed: '
        '403 Forbidden',
      );
      expect(IoGeminiSocket.statusCodeOf(error), 403);
      expect(IoGeminiSocket.describeError(error), 'HTTP 403');
      expect(IoGeminiSocket.classifyError(error), 'keyInvalid');
    });

    test('a status carried on the exception itself still classifies', () {
      expect(
        IoGeminiSocket.classifyError(
          const WebSocketException('handshake rejected', 429),
        ),
        'quotaExceeded',
      );
    });
  });
}
