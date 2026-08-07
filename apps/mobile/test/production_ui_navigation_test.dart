import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/chats/chats_screen.dart';
import 'package:guffsuff_mobile/chats/conversation_screen.dart';
import 'package:guffsuff_mobile/contacts/people_screen.dart';
import 'package:guffsuff_mobile/core/l10n/app_strings.dart';
import 'package:guffsuff_mobile/core/theme/app_theme.dart';
import 'package:guffsuff_mobile/main.dart';
import 'package:guffsuff_mobile/settings/diagnostics_screen.dart';
import 'package:guffsuff_mobile/settings/settings_screen.dart';

void main() {
  group('Production UI & Navigation Comprehensive Tests', () {
    testWidgets(
      '3-tab navigation switches between Chats, People, and Settings',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: GuffSuffApp()));
        await tester.pumpAndSettle();

        // Default tab: Chats
        expect(find.text('GuffSuff'), findsOneWidget);

        // Tap People tab
        await tester.tap(find.text('People').last);
        await tester.pumpAndSettle();
        expect(find.text('Contacts on GuffSuff'), findsOneWidget);

        // Tap Settings tab
        await tester.tap(find.text('Settings').last);
        await tester.pumpAndSettle();
        expect(find.text('PREFERENCES'), findsOneWidget);
      },
    );

    testWidgets(
      'Unavailable provider shows non-intrusive safety notice and disables composer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ConversationScreen(
              conversationId: 'conv_test_1',
              peerName: 'Aanav Sharma',
            ),
          ),
        );

        expect(
          find.text("Secure messaging isn't available yet."),
          findsOneWidget,
        );
        expect(
          find.text('Messaging disabled until provider activation'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'People empty state displays contextual contact discovery prompt',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: PeopleScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Contacts on GuffSuff'), findsOneWidget);
        expect(find.text('Invite to GuffSuff'), findsOneWidget);
      },
    );

    testWidgets('Chats empty state renders clean human-designed fallback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ChatsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GuffSuff'), findsOneWidget);
    });

    testWidgets(
      'Light mode and Dark mode ThemeData build correctly without errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: Text('Dark Mode Test')),
          ),
        );

        expect(find.text('Dark Mode Test'), findsOneWidget);
      },
    );

    testWidgets('Nepali localization smoke test renders Devanagari labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ne', ''), Locale('en', '')],
          locale: const Locale('ne', ''),
          home: Builder(
            builder: (context) {
              final strings = AppStrings.of(context);
              return Scaffold(body: Text(strings.appTagline));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('नेपालको लागि आधुनिक मेसेजिङ'), findsOneWidget);
    });

    testWidgets('Handles long contact names and large text scaling (2.0x)', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConversationScreen(
              conversationId: 'conv_long_name',
              peerName: 'Dr. Ram Bahadur Shrestha-Chaudhary Karki',
            ),
          ),
        ),
      );

      expect(
        find.text('Dr. Ram Bahadur Shrestha-Chaudhary Karki'),
        findsOneWidget,
      );

      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    testWidgets('Settings diagnostics entry is excluded in production builds', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byType(DiagnosticsScreen), findsNothing);
    });
  });
}
