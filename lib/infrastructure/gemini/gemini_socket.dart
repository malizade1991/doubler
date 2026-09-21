import 'dart:async';
import 'dart:io';

import '../../core/errors/app_failure.dart';
import 'gemini_config.dart';
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
    final redact = _secrets(endpoint);
    try {
      return await _connectOnce(endpoint);
    } on Object catch (error) {
      // A rejected upgrade that included `x-goog-api-key` is retried with the
      // documented `?key=` query alone. Some fronts accept only one of the two.
      if (endpoint.headers.isEmpty) {
        throw _asFailure(error, redact);
      }
      try {
        return await _connectOnce(GeminiLiveEndpoint(uri: endpoint.uri));
      } on Object {
        throw _asFailure(error, redact);
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

  static AppFailure _asFailure(Object error, List<String> redact) {
    if (error is AppFailure) {
      return error;
    }
    return AppFailure(
      code: classifyError(error, redact: redact),
      message: describeError(error, redact: redact),
    );
  }

  /// Every secret the endpoint carries: the `x-goog-api-key` header and the
  /// documented `?key=` query parameter.
  static List<String> _secrets(GeminiLiveEndpoint endpoint) {
    final secrets = <String>[];
    final header = endpoint.headers[GeminiConfig.apiKeyHeader];
    if (header != null && header.isNotEmpty) {
      secrets.add(header);
    }
    final query = endpoint.uri.queryParameters['key'];
    if (query != null && query.isNotEmpty) {
      secrets.add(query);
    }
    return secrets;
  }

  /// Strips [secrets] from [text] before anything is classified or logged, so
  /// a token that happens to contain "401" cannot be classified from its own
  /// characters, and so the key never reaches a log.
  static String _redact(String text, List<String> secrets) {
    var redacted = text;
    for (final secret in secrets) {
      redacted = redacted.replaceAll(secret, 'REDACTED');
    }
    return redacted;
  }

  /// A rejected HTTP upgrade means the key (or the model) is the problem;
  /// anything else is transport. Best-effort: dart:io only gives us a string.
  static String classifyError(Object error, {List<String> redact = const []}) {
    final text = _redact(error.toString(), redact).toLowerCase();
    final status = statusCodeOf(error, redact: redact);
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

  static int? statusCodeOf(Object error, {List<String> redact = const []}) {
    final match = RegExp(r'\b(4\d\d|5\d\d)\b').firstMatch(_redact(error.toString(), redact));
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  static String? describeError(Object error, {List<String> redact = const []}) {
    final status = statusCodeOf(error, redact: redact);
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

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void add(String data) => sent.add(data);

  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
    closedCode = code;
    closedReason = reason;
    await _controller.close();
  }

  @override
  int? get closeCode => closed ? closedCode : null;

  @override
  String? get closeReason => closed ? closedReason : null;
}
