import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_config.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.darkContentMuted : AppColors.lightContentMuted;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabSettings)),
      body: ListView(
        children: [
          // Compact Profile Header
          InkWell(
            onTap: () => context.push('/settings/profile'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.brandPrimary.withValues(
                      alpha: 0.15,
                    ),
                    child: const Text(
                      'R',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rahul Gupta', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Building GuffSuff for Nepal 🇳🇵',
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const Divider(),

          // Grouped Settings List
          const _SettingGroupHeader(title: 'PREFERENCES'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(
              strings.accountSettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: Text(
              strings.privacySettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline_rounded),
            title: Text(strings.chatsSettings, style: AppTypography.titleSmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: Text(
              strings.notificationsSettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(
              strings.appearanceSettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),

          const Divider(),
          const _SettingGroupHeader(title: 'SYSTEM & DATA'),
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: Text(
              strings.storageSettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.devices_rounded),
            title: Text(
              strings.devicesSettings,
              style: AppTypography.titleSmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/devices'),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(
              strings.languageSettings,
              style: AppTypography.titleSmall,
            ),
            subtitle: Text(strings.isNepali ? 'नेपाली' : 'English'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),

          const Divider(),
          const _SettingGroupHeader(title: 'HELP & ABOUT'),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: Text(strings.helpSettings, style: AppTypography.titleSmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(strings.buildInfo, style: AppTypography.titleSmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/about'),
          ),

          // Internal / Developer Entry (EXCLUDED in production)
          if (!AppConfig.isProduction) ...[
            const Divider(),
            const _SettingGroupHeader(title: 'INTERNAL BUILD DIAGNOSTICS'),
            ListTile(
              leading: const Icon(
                Icons.bug_report_outlined,
                color: AppColors.warning,
              ),
              title: Text(
                strings.diagnosticsSettings,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
              subtitle: const Text('Environment and crypto boundary status'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings/diagnostics'),
            ),
          ],

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(
              strings.logout,
              style: AppTypography.titleSmall.copyWith(color: AppColors.danger),
            ),
            onTap: () => context.go('/welcome'),
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}

class _SettingGroupHeader extends StatelessWidget {
  final String title;

  const _SettingGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s16,
        bottom: AppSpacing.s4,
      ),
      child: Text(
        title,
        style: AppTypography.metadata.copyWith(
          color:
              isDark ? AppColors.darkContentMuted : AppColors.lightContentMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
