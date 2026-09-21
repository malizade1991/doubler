import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/audio_waveform.dart';
import '../../api_key/application/api_key_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), _go);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (!mounted) {
      return;
    }
    await ref.read(apiKeyControllerProvider.future);
    if (!mounted) {
      return;
    }
    final hasKey =
        ref.read(apiKeyControllerProvider).valueOrNull?.hasKey ?? false;
    context.go(hasKey ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: l10n.appNameLatin,
          child: Center(
            child: FadeTransition(
              opacity: fade,
              child: Padding(
                padding: AppSpacing.page,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.signal,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.appNameLatin,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AudioWaveform(active: true, height: 40),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
