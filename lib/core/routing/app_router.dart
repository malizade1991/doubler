import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/api_key/presentation/api_key_setup_screen.dart';
import '../../features/api_key/presentation/gemini_config_screen.dart';
import '../../features/dubbing/presentation/audio_controls_screen.dart';
import '../../features/dubbing/presentation/live_dubbing_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/history/presentation/history_detail_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/settings/presentation/language_selection_screen.dart';
import '../../features/settings/presentation/privacy_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transcript/presentation/export_transcript_screen.dart';
import '../../features/transcript/presentation/live_transcript_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.apiKeySetup,
      builder: (BuildContext context, GoRouterState state) =>
          const ApiKeySetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.liveDubbing,
      builder: (BuildContext context, GoRouterState state) =>
          const LiveDubbingScreen(),
    ),
    GoRoute(
      path: AppRoutes.languageSelection,
      builder: (BuildContext context, GoRouterState state) =>
          const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.audioControls,
      builder: (BuildContext context, GoRouterState state) =>
          const AudioControlsScreen(),
    ),
    GoRoute(
      path: AppRoutes.liveTranscript,
      builder: (BuildContext context, GoRouterState state) =>
          const LiveTranscriptScreen(),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (BuildContext context, GoRouterState state) =>
          const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.historyDetail,
      builder: (BuildContext context, GoRouterState state) =>
          HistoryDetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (BuildContext context, GoRouterState state) =>
          const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (BuildContext context, GoRouterState state) =>
          const PrivacyScreen(),
    ),
    GoRoute(
      path: AppRoutes.geminiConfig,
      builder: (BuildContext context, GoRouterState state) =>
          const GeminiConfigScreen(),
    ),
    GoRoute(
      path: AppRoutes.exportTranscript,
      builder: (BuildContext context, GoRouterState state) =>
          const ExportTranscriptScreen(),
    ),
    GoRoute(
      path: AppRoutes.help,
      builder: (BuildContext context, GoRouterState state) =>
          const HelpScreen(),
    ),
  ],
);
