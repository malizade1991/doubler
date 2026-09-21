import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/errors/app_failure.dart';
import '../../domain/providers/translation_provider.dart';
import 'gemini_config.dart';
import 'gemini_error_mapper.dart';
import 'gemini_live_messages.dart';
import 'gemini_socket.dart';

class GeminiTranslationProvider implements TranslationProvider {
  GeminiTranslationProvider({
    GeminiSocketFactory? socketFactory,
    this.maxReconnects = 2,
    this.handshakeTimeout = const Duration(seconds: 12),
    this.connectTimeout = const Duration(seconds: 12),
  }) : _socketFactory = socketFactory ?? IoGeminiSocket.connect;

  final GeminiSocketFactory _socketFactory;
  final int maxReconnects;
  final Duration handshakeTimeout;
  final Duration connectTimeout;

  final _events = StreamController<ProviderEvent>.broadcast();
  GeminiSocket? _socket;
  SessionConfig? _config;
  StreamSubscription<dynamic>? _sub;
  Timer? _handshakeTimer;
  int _reconnects = 0;
  int _generation = 0;
  bool _intentionalClose = false;
  bool _handlingFailure = false;
  bool _failed = false;
  bool _setupComplete = false;
  bool _usedFallback = false;
  String? _resumeHandle;

  @override
  Stream<ProviderEvent> connect(SessionConfig config) {
    _config = config;
    _intentionalClose = false;
    _failed = false;
    _usedFallback = false;
    _reconnects = 0;
    unawaited(_open());
    return _events.stream;
  }

  Future<void> _open() async {
    final generation = ++_generation;
    final config = _config;
    final key = config?.apiKey;
    if (config == null || key == null || key.isEmpty) {
      // Deferred by one microtask on purpose: `connect()` hands the caller the
      // stream and only then subscribes, and a broadcast stream drops events
      // emitted while nobody is listening yet.
      unawaited(
        Future<void>.microtask(
          () => _events.add(const ProviderError('keyMissing')),
        ),
      );
      return;
    }
    _setupComplete = false;
    _handshakeTimer?.cancel();
    try {
      final socket = await _socketFactory(
        GeminiLiveEndpoint(
          uri: GeminiConfig.liveUri(key),
          headers: GeminiConfig.authHeaders(key),
        ),
      ).timeout(
        connectTimeout,
        onTimeout: () => throw const AppFailure(code: 'connectionTimeout'),
      );
      if (generation != _generation || _intentionalClose || _failed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _sub = socket.messages.listen(
        _onMessage,
        onError: (Object error) {
          unawaited(_handleFailure(_codeFor(error), reconnect: true));
        },
        onDone: () {
          if (_intentionalClose) {
            _events.add(const ProviderDisconnected());
          } else if (!_failed && !_handlingFailure) {
            final mapped = GeminiErrorMapper.fromCloseCode(
              socket.closeCode,
              socket.closeReason,
            );
            // A socket that dies before setupComplete with no reason is the
            // "stuck on connecting" failure. Name it so the button can leave.
            final code = socket.closeCode == null &&
                    (socket.closeReason == null || socket.closeReason!.isEmpty)
                ? (_setupComplete ? 'geminiUnavailable' : 'connectionTimeout')
                : mapped;
            unawaited(_handleFailure(code, reconnect: _retryable.contains(code)));
          }
        },
      );
      socket.add(
        GeminiLiveMessages.setup(config, resumeHandle: _resumeHandle),
      );
      _armHandshakeTimer(generation);
    } on Object catch (error) {
      if (generation != _generation || _intentionalClose || _failed) {
        return;
      }
      // Nested open (reconnect / model fallback) must fail closed. Re-entering
      // _handleFailure here would no-op on the in-flight guard and leave the
      // UI on «در حال اتصال» with a dead socket.
      if (_handlingFailure) {
        _fail(_codeFor(error));
        return;
      }
      await _handleFailure(_codeFor(error), reconnect: true);
    }
  }

  void _armHandshakeTimer(int generation) {
    _handshakeTimer?.cancel();
    _handshakeTimer = Timer(handshakeTimeout, () {
      if (generation != _generation || _setupComplete || _intentionalClose || _failed) {
        return;
      }
      // The socket is open but Google never acknowledged setup. Retry once,
      // then surface a timeout — never leave the button on «در حال اتصال».
      unawaited(_handleFailure('connectionTimeout', reconnect: true));
    });
  }

  /// A key/model problem must not be reported as "Gemini is down".
  static String _codeFor(Object error) {
    if (error is AppFailure) {
      return error.code;
    }
    if (error is TimeoutException) {
      return 'connectionTimeout';
    }
    return GeminiErrorMapper.fromCloseCode(null, error.toString());
  }

  void _onMessage(dynamic raw) {
    final map = GeminiLiveMessages.decode(raw);
    if (map == null) {
      return;
    }

    if (map['error'] != null) {
      final err = map['error'];
      final code = err is Map ? err['code'] : null;
      final message = err is Map ? err['message']?.toString() : err.toString();
      unawaited(
        _handleFailure(
          GeminiErrorMapper.fromCloseCode(
            code is int ? code : int.tryParse('$code'),
            message,
          ),
          reconnect: false,
        ),
      );
      return;
    }

    // `{"setupComplete": {}}` is the documented ack. Some servers also skip
    // straight to serverContent; either one means the button can leave
    // «در حال اتصال» and audio may flow.
    if (GeminiLiveMessages.isSetupComplete(map) ||
        map['serverContent'] != null ||
        map['server_content'] != null) {
      _markReady();
    }

    final goAway = map['goAway'] ?? map['go_away'];
    if (goAway != null) {
      unawaited(_maybeReconnect());
    }

    final resume = map['sessionResumptionUpdate'] ?? map['session_resumption_update'];
    if (resume is Map && resume['newHandle'] != null) {
      _resumeHandle = resume['newHandle'].toString();
      _events.add(ProviderResumed(_resumeHandle!));
    }

    final sc = map['serverContent'] ?? map['server_content'];
    if (sc is Map) {
      _handleServerContent(Map<String, dynamic>.from(sc));
    }
  }

  void _markReady() {
    if (_setupComplete || _failed || _intentionalClose) {
      return;
    }
    _setupComplete = true;
    _reconnects = 0;
    _handshakeTimer?.cancel();
    _events.add(const ProviderConnected());
  }

  void _handleServerContent(Map<String, dynamic> sc) {
    if (sc['interrupted'] == true) {
      _events.add(const ProviderSpeaking(false));
    }
    if (sc['turnComplete'] == true || sc['turn_complete'] == true) {
      _events.add(const ProviderSpeaking(false));
    }

    final inputTx = sc['inputTranscription'] ??
        sc['input_transcription'] ??
        sc['interimInputTranscription'];
    if (inputTx is Map && inputTx['text'] != null) {
      _events.add(
        ProviderTranscript(
          text: inputTx['text'].toString(),
          isInput: true,
          isFinal: inputTx['finished'] == true,
        ),
      );
    }
    final outputTx = sc['outputTranscription'] ?? sc['output_transcription'];
    if (outputTx is Map && outputTx['text'] != null) {
      _events.add(
        ProviderTranscript(
          text: outputTx['text'].toString(),
          isInput: false,
          isFinal: outputTx['finished'] == true,
        ),
      );
      _events.add(const ProviderSpeaking(true));
    }

    final turn = sc['modelTurn'] ?? sc['model_turn'];
    if (turn is Map) {
      final parts = turn['parts'];
      if (parts is List) {
        for (final part in parts) {
          if (part is! Map) {
            continue;
          }
          final inline = part['inlineData'] ?? part['inline_data'];
          if (inline is Map && inline['data'] is String) {
            final bytes = base64Decode(inline['data'] as String);
            _events.add(ProviderAudioOut(Uint8List.fromList(bytes)));
            _events.add(const ProviderSpeaking(true));
          }
        }
      }
    }
  }

  static const _retryable = {
    'connectionTimeout',
    'geminiUnavailable',
    'networkUnavailable',
  };

  Future<void> _handleFailure(String code, {required bool reconnect}) async {
    if (_intentionalClose || _failed || _handlingFailure) {
      return;
    }
    _handlingFailure = true;
    try {
      if (await _tryFallback(code)) {
        return;
      }
      if (reconnect && _retryable.contains(code) && _reconnects < maxReconnects) {
        await _maybeReconnect();
        return;
      }
      _fail(code);
    } finally {
      _handlingFailure = false;
    }
  }

  /// A key that can list models may still lack the translate preview. One
  /// silent retry on the conversational Live model is better than a dead button.
  Future<bool> _tryFallback(String code) async {
    final config = _config;
    if (config == null || _usedFallback || code != 'unsupportedModel') {
      return false;
    }
    if (!GeminiConfig.isTranslateModel(config.model)) {
      return false;
    }
    _usedFallback = true;
    _reconnects = 0;
    _handshakeTimer?.cancel();
    await _sub?.cancel();
    await _socket?.close();
    _socket = null;
    _config = SessionConfig(
      sourceLanguage: config.sourceLanguage,
      targetLanguage: config.targetLanguage,
      tone: config.tone,
      voiceId: config.voiceId,
      apiKey: config.apiKey,
      model: GeminiConfig.agentModel,
    );
    await _open();
    return true;
  }

  void _fail(String code) {
    if (_intentionalClose || _failed) {
      return;
    }
    _failed = true;
    _handshakeTimer?.cancel();
    _generation++;
    _events.add(ProviderError(code));
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close());
  }

  Future<void> _maybeReconnect() async {
    if (_intentionalClose || _failed) {
      return;
    }
    if (_reconnects >= maxReconnects) {
      _fail('geminiUnavailable');
      return;
    }
    _reconnects++;
    _handshakeTimer?.cancel();
    await _sub?.cancel();
    final previous = _socket;
    _socket = null;
    unawaited(previous?.close());
    await Future<void>.delayed(Duration(milliseconds: 400 * _reconnects));
    if (_intentionalClose || _failed) {
      return;
    }
    await _open();
  }

  @override
  void sendAudio(Uint8List pcm16k) {
    final socket = _socket;
    // The protocol requires waiting for setupComplete before any other client
    // message. Audio produced earlier is dropped rather than rejected.
    if (socket == null || !_setupComplete || pcm16k.isEmpty) {
      return;
    }
    socket.add(GeminiLiveMessages.audioChunk(pcm16k));
  }

  @override
  void updateConfig(SessionConfig patch) {
    _config = (_config ?? patch).merge(patch);
  }

  @override
  Future<void> disconnect() async {
    _intentionalClose = true;
    _failed = true;
    _generation++;
    _handshakeTimer?.cancel();
    await _sub?.cancel();
    await _socket?.close(1000, 'client');
    _socket = null;
    if (!_events.isClosed) {
      _events.add(const ProviderDisconnected());
    }
  }
}
