import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../onboarding/welcome_screen.dart';
import '../../onboarding/privacy_explain_screen.dart';
import '../../onboarding/phone_entry_screen.dart';
import '../../onboarding/otp_verification_screen.dart';
import '../../onboarding/profile_setup_screen.dart';
import '../../onboarding/permissions_intro_screen.dart';
import '../../home/home_screen.dart';
import '../../chats/conversation_screen.dart';
import '../../devices/devices_screen.dart';
import '../../settings/privacy_settings_screen.dart';
import '../../settings/diagnostics_screen.dart';
import '../../settings/about_screen.dart';
import '../../feedback/internal_feedback_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/onboarding/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/privacy',
      builder: (context, state) => const PrivacyExplainScreen(),
    ),
    GoRoute(
      path: '/onboarding/phone',
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/onboarding/otp',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/permissions',
      builder: (context, state) => const PermissionsIntroScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'c1';
        final name = state.uri.queryParameters['name'] ?? 'Chat';
        return ConversationScreen(chatId: id, chatName: name);
      },
    ),
    GoRoute(
      path: '/devices',
      builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const InternalFeedbackScreen(),
    ),
  ],
);
