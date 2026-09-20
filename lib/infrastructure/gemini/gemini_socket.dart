import 'dart:async';
import 'dart:io';

abstract class GeminiSocket {
  Stream<dynamic> get messages;
  void add(String data);
  Future<void> close([int? code, String? reason]);
}

typedef GeminiSocketFactory = Future<GeminiSocket> Function(Uri uri);

class IoGeminiSocket implements GeminiSocket {
  IoGeminiSocket(this._socket);

  final WebSocket _socket;

  static Future<GeminiSocket> connect(Uri uri) async {
    final socket = await WebSocket.connect(uri.toString());
    return IoGeminiSocket(socket);
  }

  @override
  Stream<dynamic> get messages => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);
}

class FakeGeminiSocket implements GeminiSocket {
  final _controller = StreamController<dynamic>.broadcast();
  final List<String> sent = [];
  int? closedCode;
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
    await _controller.close();
  }
}
