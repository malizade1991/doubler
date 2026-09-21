import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../infrastructure/audio/audio_lifecycle.dart';
import '../../../infrastructure/audio/audio_output.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_slider.dart';
import '../../../shared/widgets/mixed_direction_text.dart';
import '../../../shared/widgets/subtitle_stage.dart';
import '../../api_key/application/api_key_controller.dart';
import '../application/dubbing_controller.dart';

class LiveDubbingScreen extends ConsumerStatefulWidget {
  const LiveDubbingScreen({super.key});

  @override
  ConsumerState<LiveDubbingScreen> createState() => _LiveDubbingScreenState();
}

class _LiveDubbingScreenState extends ConsumerState<LiveDubbingScreen> {
  AudioLifecycleObserver? _lifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lifecycle = AudioLifecycleObserver(ref.read(audioCaptureProvider))
        ..attach();
    });
  }

  @override
  void dispose() {
    _lifecycle?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyState = ref.watch(apiKeyControllerProvider).valueOrNull;
    final hasKey = keyState?.hasKey ?? false;
    final dubbing = ref.watch(dubbingControllerProvider);
    final source = LanguageCatalog.byCode(ref.watch(sourceLanguageCodeProvider));
    final target = LanguageCatalog.byCode(ref.watch(targetLanguageCodeProvider));
    final subStyle = ref.watch(subtitleStyleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.startLiveDubbing)),
      body: Padding(
        padding: AppSpacing.page,
        child: hasKey
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${source.flag} ${source.nativeName} → ${target.flag} ${target.nativeName}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DoublerCard(child: Text(_statusLabel(l10n, dubbing))),
                  const SizedBox(height: AppSpacing.sm),
                  AudioWaveform(
                    active: dubbing.capturing || dubbing.speaking,
                  ),
                  if (dubbing.latencyMs != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DoublerCard(
                      child: Text(
                        '${l10n.latency}: ${dubbing.latencyMs} ms · ${_bandLabel(l10n, dubbing.latencyMs)}',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  DoublerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.sourceLanguage,
                            style: Theme.of(context).textTheme.labelMedium),
                        MixedDirectionText(
                          text: dubbing.line.source.isEmpty
                              ? '—'
                              : dubbing.line.source,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l10n.targetLanguage,
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          height: 96,
                          child: SubtitleStage(
                            text: dubbing.line.target,
                            style: subStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DoublerSlider(
                    label: l10n.originalVolume,
                    value: ref.watch(originalVolumeProvider),
                    onChanged: (v) =>
                        ref.read(originalVolumeProvider.notifier).state = v,
                  ),
                  DoublerSlider(
                    label: l10n.dubbedVolume,
                    value: ref.watch(dubbedVolumeProvider),
                    onChanged: (v) =>
                        ref.read(dubbedVolumeProvider.notifier).state = v,
                  ),
                  const Spacer(),
                  DoublerButton(
                    label: l10n.liveTranscript,
                    variant: DoublerButtonVariant.ghost,
                    onPressed: () => context.push(AppRoutes.liveTranscript),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DoublerButton(
                    label: l10n.startSession,
                    onPressed: dubbing.phase == DubbingPhase.connecting
                        ? null
                        : () =>
                            ref.read(dubbingControllerProvider.notifier).start(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DoublerButton(
                    label: l10n.stopSession,
                    variant: DoublerButtonVariant.secondary,
                    onPressed: () =>
                        ref.read(dubbingControllerProvider.notifier).stop(),
                  ),
                ],
              )
            : Column(
                children: [
                  DoublerCard(child: Text(l10n.liveRequiresKey)),
                  const SizedBox(height: AppSpacing.md),
                  DoublerButton(
                    label: l10n.apiKeySetup,
                    onPressed: () => context.push(AppRoutes.apiKeySetup),
                  ),
                ],
              ),
      ),
    );
  }

  String _bandLabel(AppLocalizations l10n, int? ms) {
    return switch (latencyBand(ms)) {
      LatencyBand.good => l10n.latencyGood,
      LatencyBand.fair => l10n.latencyFair,
      LatencyBand.poor => l10n.latencyPoor,
    };
  }

  String _statusLabel(AppLocalizations l10n, DubbingUiState dubbing) {
    if (dubbing.errorCode != null) {
      return l10n.message(dubbing.errorCode);
    }
    if (dubbing.speaking) {
      return l10n.speaking;
    }
    if (dubbing.line.source.isNotEmpty && dubbing.line.target.isEmpty) {
      return l10n.translating;
    }
    if (dubbing.phase == DubbingPhase.live && dubbing.capturing) {
      return l10n.listening;
    }
    return switch (dubbing.phase) {
      DubbingPhase.idle => l10n.shellPlaceholder,
      DubbingPhase.connecting => l10n.connecting,
      DubbingPhase.live => l10n.live,
      DubbingPhase.error => l10n.message(dubbing.errorCode),
      DubbingPhase.disconnected => l10n.disconnected,
    };
  }
}
