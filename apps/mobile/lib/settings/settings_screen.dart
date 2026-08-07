import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabSettings)),
      body: ListView(
        children: [
          // Profile Header Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryNavy.withOpacity(0.2),
                    child: Text(
                      profile?.displayName.isNotEmpty == true
                          ? profile!.displayName[0]
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? 'Demo User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile?.phoneNumber ?? '+977 9800000000',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '@${profile?.username ?? 'nepal_user'}',
                          style: const TextStyle(
                            color: AppTheme.primaryNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.shield_outlined,
              color: AppTheme.primaryNavy,
            ),
            title: Text(strings.privacySettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(
              Icons.devices_outlined,
              color: AppTheme.primaryNavy,
            ),
            title: Text(strings.devicesSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/devices'),
          ),
          ListTile(
            leading: const Icon(
              Icons.language_outlined,
              color: AppTheme.primaryNavy,
            ),
            title: Text(strings.languageSettings),
            subtitle: Text(
              ref.watch(localeProvider).languageCode == 'ne'
                  ? 'नेपाली (Nepali)'
                  : 'English',
            ),
            onTap: () {
              final current = ref.read(localeProvider);
              ref.read(localeProvider.notifier).state =
                  current.languageCode == 'en'
                      ? const Locale('ne')
                      : const Locale('en');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: Colors.amber),
            title: Text(strings.diagnosticsSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/diagnostics'),
          ),
          ListTile(
            leading: const Icon(
              Icons.feedback_outlined,
              color: AppTheme.primaryNavy,
            ),
            title: Text(strings.internalFeedback),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/feedback'),
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppTheme.primaryNavy,
            ),
            title: Text(strings.buildInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/about'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              strings.logout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/onboarding/welcome');
            },
          ),
        ],
      ),
    );
  }
}
