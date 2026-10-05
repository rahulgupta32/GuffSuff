import '../../services/auth_session.dart';
import '../config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../chats/chats_screen.dart';
import '../../chats/conversation_screen.dart';
import '../../chats/new_chat_sheet.dart';
import '../../contacts/people_screen.dart';
import '../../devices/devices_screen.dart';
import '../../onboarding/otp_verification_screen.dart';
import '../../onboarding/phone_entry_screen.dart';
import '../../onboarding/privacy_explain_screen.dart';
import '../../onboarding/profile_setup_screen.dart';
import '../../onboarding/welcome_screen.dart';
import '../../settings/about_screen.dart';
import '../../settings/diagnostics_screen.dart';
import '../../settings/privacy_settings_screen.dart';
import '../../settings/profile_screen.dart';
import '../../settings/settings_screen.dart';
import '../widgets/app_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  refreshListenable: authSession,
  redirect: (context, state) {
    final path = state.uri.path;
    final onboarding = [
      '/welcome',
      '/privacy-explain',
      '/phone-entry',
      '/otp-verification',
      '/profile-setup',
    ].contains(path);
    if (!authSession.isAuthenticated && !onboarding) return '/welcome';
    if (authSession.isAuthenticated && onboarding) return '/chats';
    if (path == '/settings/diagnostics' && AppConfig.isProduction) {
      return '/settings';
    }
    if (path == '/otp-verification' && state.extra is! RegistrationChallenge) {
      return '/phone-entry';
    }
    if (path == '/profile-setup' &&
        (state.extra is! RegistrationChallenge ||
            !(state.extra as RegistrationChallenge).verified)) {
      return '/phone-entry';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/privacy-explain',
      builder: (context, state) => const PrivacyExplainScreen(),
    ),
    GoRoute(
      path: '/phone-entry',
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        return OtpVerificationScreen(
          challenge: state.extra as RegistrationChallenge,
        );
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder:
          (context, state) => ProfileSetupScreen(
            challenge: state.extra as RegistrationChallenge,
          ),
    ),

    // 3-Tab Shell Route
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        int index = 0;
        final loc = state.uri.path;
        if (loc.startsWith('/people')) {
          index = 1;
        } else if (loc.startsWith('/settings')) {
          index = 2;
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: AppBottomNav(
            currentIndex: index,
            onTap: (i) {
              switch (i) {
                case 0:
                  context.go('/chats');
                  break;
                case 1:
                  context.go('/people');
                  break;
                case 2:
                  context.go('/settings');
                  break;
              }
            },
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatsScreen(),
        ),
        GoRoute(
          path: '/people',
          builder: (context, state) => const PeopleScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    // Sub-screens outside bottom nav shell
    GoRoute(
      path: '/chats/new',
      builder: (context, state) => const NewChatScreen(),
    ),
    GoRoute(
      path: '/chats/conversation/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final name = state.uri.queryParameters['name'] ?? 'Chat';
        return ConversationScreen(
          conversationId: id,
          peerName: Uri.decodeComponent(name),
        );
      },
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/devices',
      builder: (context, state) => const LinkedDevicesScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/settings/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
  ],
);
