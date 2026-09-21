import 'dart:async';
import 'dart:io';

import '../../core/errors/app_failure.dart';
import 'gemini_error_mapper.dart';

/// Where and how to open the Live socket. [headers] carries the API key
/// (`x-goog-api-key`) so a rejected key can be told apart from a dead network.
class GeminiLiveEndpoint {
  const GeminiLiveEndpoint({required this.uri, this.headers = const {}});

  final Uri uri;
  final Map<String, String> headers;
}

abstract class GeminiSocket {
  Stream<dynamic> get messages;
  void add(String data);
  Future<void> close([int? code, String? reason]);

  /// Populated after the socket closes. Null while it is still open.
  int? get closeCode;
  String? get closeReason;
}

typedef GeminiSocketFactory = Future<GeminiSocket> Function(
  GeminiLiveEndpoint endpoint,
);

class IoGeminiSocket implements GeminiSocket {
  IoGeminiSocket(this._socket);

  final WebSocket _socket;

  static Future<GeminiSocket> connect(GeminiLiveEndpoint endpoint) async {
    try {
      return await _connectOnce(endpoint);
    } on Object catch (error) {
      // A rejected upgrade that included `x-goog-api-key` is retried with the
      // documented `?key=` query alone. Some fronts accept only one of the two.
      if (endpoint.headers.isEmpty) {
        throw _asFailure(error);
      }
      try {
        return await _connectOnce(GeminiLiveEndpoint(uri: endpoint.uri));
      } on Object {
        throw _asFailure(error);
      }
    }
  }

  static Future<GeminiSocket> _connectOnce(GeminiLiveEndpoint endpoint) async {
    final socket = await WebSocket.connect(
      endpoint.uri.toString(),
      headers: endpoint.headers.isEmpty ? null : endpoint.headers,
    );
    return IoGeminiSocket(socket);
  }

  static AppFailure _asFailure(Object error) {
    if (error is AppFailure) {
      return error;
    }
    return AppFailure(
      code: classifyError(error),
      message: describeError(error),
    );
  }

  /// Strips API keys out of [text] before it is classified or logged, so a
  /// token that happens to contain "401" cannot be classified from its own
  /// characters and so a key never reaches a log. Covers `key=` / `api-key:`
  /// labels (including `?key=` query parts and `x-goog-api-key` headers) and
  /// bare `AIza…` / `AQ.…` keys, which is every shape Google has shipped.
  static String _redact(String text) {
    return text
        .replaceAllMapped(
          RegExp(
            r'''((?:x[-\s]?goog[-\s]?api[-\s]?key|api[-\s]?key|key)\s*[:=]\s*)[^\s&"'\(\)\[\]\{\},;]+''',
            caseSensitive: false,
          ),
          (match) => '${match[1]}REDACTED',
        )
        .replaceAll(RegExp(r'AIza[0-9A-Za-z_\-]+'), 'REDACTED')
        .replaceAll(RegExp(r'AQ[.][0-9A-Za-z_.\-]+'), 'REDACTED');
  }

  /// A rejected HTTP upgrade means the key (or the model) is the problem;
  /// anything else is transport. Best-effort: dart:io only gives us a string.
  /// The key is stripped first so a token that happens to contain "401" cannot
  /// be classified from its own characters, and so it never reaches a log.
  static String classifyError(Object error) {
    final text = _redact(error.toString()).toLowerCase();
    final status = statusCodeOf(error);
    if (status != null) {
      return GeminiErrorMapper.fromHttpStatus(status);
    }
    if (text.contains('401') || text.contains('403') || text.contains('denied')) {
      return 'keyInvalid';
    }
    if (text.contains('429') || text.contains('quota')) {
      return 'quotaExceeded';
    }
    return 'geminiUnavailable';
  }

  static int? statusCodeOf(Object error) {
    // Redacted too: an `AQ.…` key contains dots, so a status-shaped run of
    // digits inside the key must not be read as an HTTP status.
    final match =
        RegExp(r'\b(4\d\d|5\d\d)\b').firstMatch(_redact(error.toString()));
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  static String? describeError(Object error) {
    final status = statusCodeOf(error);
    return status == null ? null : 'HTTP $status';
  }

  @override
  Stream<dynamic> get messages => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  int? get closeCode => _socket.closeCode;

  @override
  String? get closeReason => _socket.closeReason;

  @override
  Future<void> close([int? code, String? reason]) => _socket.close(code, reason);
}

class FakeGeminiSocket implements GeminiSocket {
  FakeGeminiSocket();

  final _controller = StreamController<dynamic>.broadcast();
  final List<String> sent = [];
  int? closedCode;
  String? closedReason;
  bool closed = false;

  void emit(dynamic message) => _controller.add(message);

  void emitError(Object error) => _controller.addError(error);

  /// Simulates the peer dropping the connection, close frame included, so the
  /// provider's `onDone` path runs the way a real close runs it — that path
  /// classifies the failure from [closeCode]/[closeReason], not from a message.
  void remoteClose({int? code, String? reason}) {
    closedCode = code;
    closedReason = reason;
    unawaited(_controller.close());
  }

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void add(String data) => sent.add(data);

  @override
  int? get closeCode => closedCode;

  @override
  String? get closeReason => closedReason;

  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
    closedCode = code;
    closedReason = reason;
    await _controller.close();
  }
}
