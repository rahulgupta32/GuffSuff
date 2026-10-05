import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'services/auth_session.dart';
import 'services/envelope_api.dart';
import 'services/message_journal.dart';
import 'services/message_sync.dart';
import 'services/message_sync_lifecycle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  await authSession.restore();
  final sync = MessageSync(
    api: EnvelopeApi(authSession),
    journalFactory:
        (userId, deviceId) => MessageJournal(
          storage: authSession.storage,
          userId: userId,
          deviceId: deviceId,
        ),
  );
  runApp(
    ProviderScope(
      child: MessageSyncLifecycle(sync: sync, child: const GuffSuffApp()),
    ),
  );
}

class GuffSuffApp extends StatelessWidget {
  const GuffSuffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'गफसफ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ne', '')],
      routerConfig: appRouter,
    );
  }
}
