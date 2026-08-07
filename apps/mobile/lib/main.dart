import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/branding/app_theme.dart';
import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: GuffSuffApp()));
}

class GuffSuffApp extends ConsumerWidget {
  const GuffSuffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'GuffSuff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: activeLocale,
      supportedLocales: const [Locale('en', ''), Locale('ne', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
