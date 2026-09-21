import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/models/dubbing_session.dart';
import '../../../domain/providers/translation_provider.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../infrastructure/audio/audio_capture.dart';
import '../../../infrastructure/audio/audio_mixer.dart';
import '../../../infrastructure/audio/audio_output.dart';
import '../../../infrastructure/audio/platform_audio_bridge.dart';
import '../../../infrastructure/gemini/gemini_translation_provider.dart';
import '../../api_key/application/api_key_controller.dart';
import '../../history/application/history_controller.dart';
import '../../transcript/application/transcript_controller.dart';

/// YouTube / other-app audio is the product default: start, leave, translate.
final captureSourceProvider =
    StateProvider<CaptureSource>((ref) => CaptureSource.playback);

final openYouTubeOnStartProvider = StateProvider<bool>((ref) => true);

final translationProviderFactory = Provider<TranslationProvider>(
  (ref) => GeminiTranslationProvider(),
);

final audioCaptureProvider = Provider<AudioCapture>(
  (ref) => PlatformAudioCapture(),
);

final audioOutputProvider = Provider<AudioOutput>(
  (ref) => PlatformAudioOutput(),
);

final audioMixerProvider = Provider<AudioMixer>((ref) => AudioMixer());

enum DubbingPhase { idle, connecting, live, error, disconnected }

class LiveLine {
  const LiveLine({this.source = '', this.target = ''});

  final String source;
  final String target;

  LiveLine copyWith({String? source, String? target}) {
    return LiveLine(
      source: source ?? this.source,
      target: target ?? this.target,
    );
  }
}

class DubbingUiState {
  const DubbingUiState({
    this.phase = DubbingPhase.idle,
    this.errorCode,
    this.statusCode,
    this.capturing = false,
    this.speaking = false,
    this.line = const LiveLine(),
    this.latencyMs,
    this.source = CaptureSource.playback,
    this.fellBackToMic = false,
  });

  final DubbingPhase phase;
  final String? errorCode;

  /// Non-error status while connecting (`awaitingCapture`, `connectingGemini`).
  final String? statusCode;
  final bool capturing;
  final bool speaking;
  final LiveLine line;
  final int? latencyMs;
  final CaptureSource source;
  final bool fellBackToMic;

  DubbingUiState copyWith({
    DubbingPhase? phase,
    String? errorCode,
    String? statusCode,
    bool? capturing,
    bool? speaking,
    LiveLine? line,
    int? latencyMs,
    CaptureSource? source,
    bool? fellBackToMic,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return DubbingUiState(
      phase: phase ?? this.phase,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      statusCode: clearStatus ? null : (statusCode ?? this.statusCode),
      capturing: capturing ?? this.capturing,
      speaking: speaking ?? this.speaking,
      line: line ?? this.line,
      latencyMs: latencyMs ?? this.latencyMs,
      source: source ?? this.source,
      fellBackToMic: fellBackToMic ?? this.fellBackToMic,
    );
  }
}

final dubbingControllerProvider =
    NotifierProvider<DubbingController, DubbingUiState>(DubbingController.new);

class DubbingController extends Notifier<DubbingUiState> {
  StreamSubscription<ProviderEvent>? _sub;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<String>? _controlSub;
  DateTime? _lastMicAt;
  DateTime? _sessionStarted;
  bool _awaitingFirstAudio = false;

  @override
  DubbingUiState build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      unawaited(_micSub?.cancel());
      unawaited(_controlSub?.cancel());
    });
    return const DubbingUiState();
  }

  Future<void> start() async {
    final store = ref.read(secureKeyStoreProvider);
    final key = await store.readApiKey();
    if (key == null || key.isEmpty) {
      state = const DubbingUiState(
        phase: DubbingPhase.error,
        errorCode: 'keyMissing',
      );
      return;
    }

    final requested = ref.read(captureSourceProvider);
    final l10n = AppLocalizations(ref.read(localeProvider));
    state = DubbingUiState(
      phase: DubbingPhase.connecting,
      statusCode: 'awaitingCapture',
      source: requested,
    );
    _sessionStarted = DateTime.now();
    ref.read(transcriptControllerProvider.notifier).startSession();

    final capture = ref.read(audioCaptureProvider);
    capture.continueInBackground = true;
    await _listenControls(capture);

    var active = requested;
    var fellBack = false;
    var armError = await capture.arm(
      requested,
      notificationTitle: l10n.message('notificationTitle'),
      notificationBody: l10n.message('notificationBody'),
      notificationStop: l10n.message('notificationStop'),
    );
    // YouTube capture needs a consent dialog. If the user denies it, or the
    // OS cannot share other-app audio, keep going on the microphone so the
    // session is not a dead spinner — and say so.
    if (armError != null && requested == CaptureSource.playback) {
      fellBack = true;
      active = CaptureSource.microphone;
      armError = await capture.arm(
        CaptureSource.microphone,
        notificationTitle: l10n.message('notificationTitle'),
        notificationBody: l10n.message('notificationBody'),
        notificationStop: l10n.message('notificationStop'),
      );
    }
    if (armError != null) {
      state = DubbingUiState(
        phase: DubbingPhase.error,
        errorCode: armError,
        source: active,
        fellBackToMic: fellBack,
      );
      return;
    }

    // Start capturing now, not after the handshake: the first words must not
    // be lost because the socket was still opening. The provider drops frames
    // until setupComplete instead of erroring.
    await _startCapture();
    state = state.copyWith(
      phase: DubbingPhase.connecting,
      statusCode: fellBack ? 'playbackFallback' : 'connectingGemini',
      capturing: true,
      source: active,
      fellBackToMic: fellBack,
      clearError: true,
    );

    final engine = ref.read(translationProviderFactory);
    final source = ref.read(sourceLanguageCodeProvider);
    final target = ref.read(targetLanguageCodeProvider);
    final tone = ref.read(translationToneProvider);
    _sub = engine
        .connect(
          SessionConfig(
            sourceLanguage: source,
            targetLanguage: target,
            tone: tone.id,
            voiceId: ref.read(voiceIdProvider),
            model: ref.read(geminiModelProvider),
            apiKey: key,
          ),
        )
        .listen(_onEvent);
  }

  Future<void> _listenControls(AudioCapture capture) async {
    await _controlSub?.cancel();
    _controlSub = capture.sessionEvents.listen((event) {
      if (event == PlatformAudioBridge.controlStop) {
        unawaited(stop());
      } else if (event == PlatformAudioBridge.controlInterrupted) {
        onInterruption(AudioInterruption.phoneCall);
      } else if (event == PlatformAudioBridge.controlResumed) {
        onInterruption(AudioInterruption.none);
      }
    });
  }

  Future<void> _startCapture() async {
    await _micSub?.cancel();
    final capture = ref.read(audioCaptureProvider);
    final engine = ref.read(translationProviderFactory);
    _micSub = capture.start().listen((pcm) {
      _lastMicAt = DateTime.now();
      _awaitingFirstAudio = true;
      engine.sendAudio(pcm);
    });
    state = state.copyWith(capturing: true);
  }

  void _onEvent(ProviderEvent event) {
    switch (event) {
      case ProviderConnected():
        state = state.copyWith(
          phase: DubbingPhase.live,
          capturing: true,
          clearStatus: true,
          clearError: true,
        );
        unawaited(ref.read(audioOutputProvider).start());
        applyMix();
      case ProviderError(:final code):
        unawaited(ref.read(audioCaptureProvider).pause());
        unawaited(ref.read(audioOutputProvider).pause());
        state = state.copyWith(
          phase: DubbingPhase.error,
          errorCode: code,
          clearStatus: true,
        );
      case ProviderDisconnected():
        if (state.phase == DubbingPhase.error) {
          break;
        }
        unawaited(ref.read(audioCaptureProvider).stop());
        unawaited(ref.read(audioOutputProvider).stop());
        state = state.copyWith(
          phase: DubbingPhase.disconnected,
          capturing: false,
          clearStatus: true,
        );
      case ProviderTranscript(:final text, :final isInput, :final isFinal):
        state = state.copyWith(
          line: isInput
              ? state.line.copyWith(source: text)
              : state.line.copyWith(target: text),
        );
        final transcript = ref.read(transcriptControllerProvider.notifier);
        if (isInput) {
          transcript.addSource(text, isFinal: isFinal);
        } else {
          transcript.addTranslation(text, isFinal: isFinal);
        }
      case ProviderSpeaking(:final active):
        state = state.copyWith(speaking: active);
        _applyMix(speaking: active);
      case ProviderAudioOut(:final pcm24k):
        _applyMix(speaking: true);
        ref.read(audioOutputProvider).enqueue(pcm24k);
        if (_awaitingFirstAudio && _lastMicAt != null) {
          final ms = DateTime.now().difference(_lastMicAt!).inMilliseconds;
          _awaitingFirstAudio = false;
          state = state.copyWith(speaking: true, latencyMs: ms);
        } else {
          state = state.copyWith(speaking: true);
        }
      default:
        break;
    }
  }

  void applyMix({bool? speaking}) {
    _applyMix(speaking: speaking ?? state.speaking);
  }

  void _applyMix({required bool speaking}) {
    final mixer = ref.read(audioMixerProvider);
    final playback = state.source == CaptureSource.playback && !state.fellBackToMic;
    mixer.microphoneMode = !playback;
    mixer.originalVolume = ref.read(originalVolumeProvider);
    mixer.dubbedVolume = ref.read(dubbedVolumeProvider);
    mixer.smartDucking = ref.read(smartDuckingProvider);
    mixer.speaking = speaking;
    final output = ref.read(audioOutputProvider);
    output.setGain(mixer.effectiveDubbedGain);
    final duck = playback &&
        ((mixer.smartDucking && speaking) || mixer.originalVolume < 0.08);
    output.setOriginalPolicy(
      originalGain: mixer.effectiveOriginalGain,
      duck: duck,
    );
  }

  Future<void> pauseCapture() async {
    await ref.read(audioCaptureProvider).pause();
    state = state.copyWith(capturing: false);
  }

  Future<void> resumeCapture() async {
    await ref.read(audioCaptureProvider).resume();
    state = state.copyWith(capturing: true);
  }

  void onInterruption(AudioInterruption event) {
    ref.read(audioCaptureProvider).handleInterruption(event);
    final paused = event != AudioInterruption.none &&
        event != AudioInterruption.routeChange;
    state = state.copyWith(capturing: !paused);
  }

  Future<void> stop() async {
    final started = _sessionStarted ?? DateTime.now();
    await ref.read(historyControllerProvider.notifier).save(
          DubbingSession(
            id: started.millisecondsSinceEpoch.toString(),
            startedAt: started,
            sourceLanguage: ref.read(sourceLanguageCodeProvider),
            targetLanguage: ref.read(targetLanguageCodeProvider),
            duration: DateTime.now().difference(started),
            transcript: ref.read(transcriptControllerProvider).segments,
            status: SessionStatus.completed,
          ),
        );
    await _micSub?.cancel();
    await ref.read(audioCaptureProvider).stop();
    await ref.read(audioOutputProvider).stop();
    await _sub?.cancel();
    await ref.read(translationProviderFactory).disconnect();
    state = const DubbingUiState(phase: DubbingPhase.idle);
  }
}
