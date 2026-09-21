import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/language_catalog.dart';
import '../../../infrastructure/audio/audio_capture.dart';
import '../../../infrastructure/audio/audio_lifecycle.dart';
import '../../../infrastructure/audio/audio_output.dart';
import '../../../infrastructure/audio/youtube_launcher.dart';
import '../application/youtube_handoff.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../../shared/widgets/doubler_button.dart';
import '../../../shared/widgets/doubler_card.dart';
import '../../../shared/widgets/doubler_feedback.dart';
import '../../../shared/widgets/doubler_scaffold.dart';
import '../../../shared/widgets/doubler_slider.dart';
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
  bool _showControls = false;
  bool _handedOff = false;

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

  Future<void> _toggleSession(DubbingUiState dubbing) async {
    final controller = ref.read(dubbingControllerProvider.notifier);
    if (dubbing.phase == DubbingPhase.idle ||
        dubbing.phase == DubbingPhase.error ||
        dubbing.phase == DubbingPhase.disconnected) {
      _handedOff = false;
      await controller.start();
      return;
    }
    await controller.stop();
  }

  Future<void> _openYouTube() async {
    await Future<void>.delayed(youtubeHandoffDelay);
    if (!mounted) {
      return;
    }
    if (ref.read(dubbingControllerProvider).phase != DubbingPhase.live) {
      return;
    }
    await ref.read(youtubeLauncherProvider).open();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasKey =
        ref.watch(apiKeyControllerProvider).valueOrNull?.hasKey ?? false;
    final dubbing = ref.watch(dubbingControllerProvider);
    final sourceLang = LanguageCatalog.byCode(ref.watch(sourceLanguageCodeProvider));
    final target = LanguageCatalog.byCode(ref.watch(targetLanguageCodeProvider));
    final subStyle = ref.watch(subtitleStyleProvider);
    final busy = dubbing.phase == DubbingPhase.connecting;
    final live = dubbing.phase == DubbingPhase.live;
    final captureSource = ref.watch(captureSourceProvider);
    final openOnStart = ref.watch(openYouTubeOnStartProvider);
    final youtubeMode =
        captureSource == CaptureSource.playback && !dubbing.fellBackToMic;

    ref.listen(dubbingControllerProvider, (previous, next) {
      if (!shouldOpenYouTube(
        wasLive: previous?.phase == DubbingPhase.live,
        isLive: next.phase == DubbingPhase.live,
        enabled: ref.read(openYouTubeOnStartProvider),
        alreadyOpened: _handedOff,
      )) {
        return;
      }
      _handedOff = true;
      unawaited(_openYouTube());
    });

    return DoublerScaffold(
      title: l10n.startLiveDubbing,
      actions: [
        IconButton(
          tooltip: l10n.audioControls,
          onPressed: () => context.push(AppRoutes.audioControls),
          icon: const Icon(Icons.tune),
        ),
        IconButton(
          tooltip: l10n.liveTranscript,
          onPressed: () => context.push(AppRoutes.liveTranscript),
          icon: const Icon(Icons.closed_caption_outlined),
        ),
      ],
      body: !hasKey
          ? DoublerEmptyState(
              icon: Icons.vpn_key_outlined,
              title: l10n.liveRequiresKey,
              message: l10n.byokExplainer,
              action: DoublerButton(
                label: l10n.apiKeySetup,
                icon: Icons.vpn_key_outlined,
                expanded: false,
                onPressed: () => context.push(AppRoutes.apiKeySetup),
              ),
            )
          : DoublerPage(
              children: [
                _StatusBar(l10n: l10n, dubbing: dubbing),
                const SizedBox(height: AppSpacing.md),
                if (!live) ...[
                  Text(
                    l10n.message('captureSource'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      DoublerChoicePill(
                        label: l10n.message('youtubeMode'),
                        icon: Icons.smart_display_outlined,
                        selected: captureSource == CaptureSource.playback,
                        onSelected: () {
                          if (busy) {
                            return;
                          }
                          ref.read(captureSourceProvider.notifier).state =
                              CaptureSource.playback;
                        },
                      ),
                      DoublerChoicePill(
                        label: l10n.message('micMode'),
                        icon: Icons.mic_none,
                        selected: captureSource == CaptureSource.microphone,
                        onSelected: () {
                          if (busy) {
                            return;
                          }
                          ref.read(captureSourceProvider.notifier).state =
                              CaptureSource.microphone;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    youtubeMode ? l10n.message('youtubeHint') : l10n.micModeMixNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (youtubeMode) ...[
                    const SizedBox(height: AppSpacing.xs),
                    DoublerSwitchRow(
                      title: l10n.message('openYouTubeOnStart'),
                      value: openOnStart,
                      onChanged: (value) {
                        if (busy) {
                          return;
                        }
                        ref.read(openYouTubeOnStartProvider.notifier).state = value;
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                if (live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DoublerStatusBanner(
                          mood: DoublerMood.success,
                          icon: Icons.smart_display_outlined,
                          message: dubbing.fellBackToMic
                              ? l10n.message('playbackFallback')
                              : l10n.message('youtubeLiveHint'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DoublerButton(
                          label: l10n.message('openYouTube'),
                          icon: Icons.open_in_new,
                          variant: DoublerButtonVariant.secondary,
                          onPressed: () {
                            unawaited(ref.read(youtubeLauncherProvider).open());
                          },
                        ),
                      ],
                    ),
                  ),
                DoublerCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sourceLang.flag} ${sourceLang.nativeName}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Text(
                          '${target.flag} ${target.nativeName}',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DoublerCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.sourceLanguage,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (dubbing.capturing)
                            DoublerPill(
                              label: youtubeMode ? 'YT' : 'MIC',
                              icon: youtubeMode
                                  ? Icons.smart_display
                                  : Icons.mic,
                              color: AppColors.live,
                              dense: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        dubbing.line.source.isEmpty ? '—' : dubbing.line.source,
                        style: theme.textTheme.bodyLarge,
                        textDirection: TextDirection.ltr,
                      ),
                      const Divider(height: AppSpacing.lg),
                      Text(
                        l10n.targetLanguage,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SizedBox(
                        height: 132,
                        child: SubtitleStage(
                          text: dubbing.line.target,
                          style: subStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AudioWaveform(active: dubbing.capturing || dubbing.speaking),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  youtubeMode ? l10n.message('youtubeSilenceHint') : l10n.headphonesNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (dubbing.errorCode != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  DoublerStatusBanner(
                    mood: DoublerMood.error,
                    message: l10n.message(dubbing.errorCode),
                    action: DoublerButton(
                      label: l10n.tryAgain,
                      expanded: false,
                      variant: DoublerButtonVariant.ghost,
                      onPressed: () => _toggleSession(dubbing),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _MoreControls(
                  expanded: _showControls,
                  onToggle: () => setState(() => _showControls = !_showControls),
                  label: l10n.mixingControls,
                  children: [
                    DoublerSlider(
                      label: l10n.originalVolume,
                      icon: Icons.volume_down,
                      value: ref.watch(originalVolumeProvider),
                      onChanged: (v) {
                        ref.read(originalVolumeProvider.notifier).state = v;
                        ref.read(dubbingControllerProvider.notifier).applyMix();
                      },
                    ),
                    DoublerSlider(
                      label: l10n.dubbedVolume,
                      icon: Icons.record_voice_over_outlined,
                      value: ref.watch(dubbedVolumeProvider),
                      onChanged: (v) {
                        ref.read(dubbedVolumeProvider.notifier).state = v;
                        ref.read(dubbingControllerProvider.notifier).applyMix();
                      },
                    ),
                    Text(
                      l10n.micModeMixNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomBar: hasKey
          ? DoublerActionRow(
              children: [
                Row(
                  children: [
                    DoublerIconButton(
                      icon: dubbing.capturing
                          ? Icons.mic_off
                          : Icons.mic_none,
                      tooltip: dubbing.capturing ? l10n.muteMic : l10n.unmuteMic,
                      selected: !dubbing.capturing && live,
                      onPressed: live
                          ? () {
                              if (dubbing.capturing) {
                                ref
                                    .read(dubbingControllerProvider.notifier)
                                    .pauseCapture();
                              } else {
                                ref
                                    .read(dubbingControllerProvider.notifier)
                                    .resumeCapture();
                              }
                            }
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DoublerButton(
                        label: busy
                            ? l10n.cancel
                            : live
                                ? l10n.stopSession
                                : (youtubeMode && openOnStart)
                                    ? l10n.message('startAndOpenYouTube')
                                    : l10n.startSession,
                        icon: busy
                            ? Icons.close_rounded
                            : live
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                        variant: live
                            ? DoublerButtonVariant.destructive
                            : DoublerButtonVariant.primary,
                        onPressed: () => _toggleSession(dubbing),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.l10n, required this.dubbing});

  final AppLocalizations l10n;
  final DubbingUiState dubbing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = dubbing.phase == DubbingPhase.live && dubbing.capturing;
    return DoublerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dubbing.errorCode != null
                  ? AppColors.danger
                  : live
                      ? AppColors.live
                      : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _statusLabel(l10n, dubbing),
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (dubbing.latencyMs != null)
            DoublerPill(
              label: '${l10n.latency} ${dubbing.latencyMs} ms · ${_bandLabel(l10n, dubbing.latencyMs)}',
              icon: Icons.speed,
              dense: true,
              color: switch (latencyBand(dubbing.latencyMs)) {
                LatencyBand.good => AppColors.success,
                LatencyBand.fair => AppColors.warning,
                LatencyBand.poor => AppColors.danger,
              },
            ),
        ],
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
    if (dubbing.phase == DubbingPhase.connecting && dubbing.statusCode != null) {
      return l10n.message(dubbing.statusCode);
    }
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
      DubbingPhase.idle => l10n.sessionIdle,
      DubbingPhase.connecting => l10n.connecting,
      DubbingPhase.live => l10n.live,
      DubbingPhase.error => l10n.message(dubbing.errorCode),
      DubbingPhase.disconnected => l10n.disconnected,
    };
  }
}

class _MoreControls extends StatelessWidget {
  const _MoreControls({
    required this.expanded,
    required this.onToggle,
    required this.label,
    required this.children,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DoublerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ],
      ),
    );
  }
}
