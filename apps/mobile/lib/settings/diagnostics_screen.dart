import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../core/config/app_config.dart';
import '../crypto/provider_neutral_boundary.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    const MobileCryptoProvider activeProvider = UnavailableCryptoProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('BUILD & ENVIRONMENT'),
          _buildInfoRow(
              'Environment', AppConfig.environment.name.toUpperCase()),
          _buildInfoRow('API Endpoint', AppConfig.apiBaseUrl),
          _buildInfoRow('WebSocket Endpoint', AppConfig.wsBaseUrl),
          _buildInfoRow(
              'App Version', '${AppConfig.appVersion}+${AppConfig.buildNumber}'),
          _buildInfoRow('Git Commit SHA', AppConfig.commitSha),
          _buildInfoRow(
              'Build Mode', AppConfig.isInternalDemo ? 'INTERNAL DEMO' : 'PRODUCTION'),
          _buildInfoRow(
            'Development OTP Mode',
            AppConfig.allowDevelopmentOtp
                ? 'ENABLED (${AppConfig.developmentOtpCode})'
                : 'DISABLED (PROHIBITED)',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('CRYPTOGRAPHIC PROVIDER BOUNDARY'),
          _buildInfoRow('Provider Available',
              activeProvider.isAvailable ? 'YES' : 'NO (FAIL-CLOSED)'),
          _buildInfoRow(
              'Provider ID', activeProvider.queryCapabilities().providerId),
          _buildInfoRow(
              'Direct Messaging',
              activeProvider.queryCapabilities().supportsDirectMessaging
                  ? 'SUPPORTED'
                  : 'DISABLED'),
          _buildInfoRow(
              'Group Messaging',
              activeProvider.queryCapabilities().supportsGroupMessaging
                  ? 'SUPPORTED'
                  : 'DISABLED'),

          const SizedBox(height: 24),
          _buildSectionHeader('AUTHENTICATION & SESSION STATE'),
          _buildInfoRow(
              'Authenticated', authState.isAuthenticated ? 'TRUE' : 'FALSE'),
          _buildInfoRow(
              'User ID', authState.profile?.userId ?? 'Not authenticated'),
          _buildInfoRow(
              'Device ID', authState.deviceId ?? 'dev_android_emulator'),
          _buildInfoRow('Push Token Status', 'SIMULATED_PUSH_TOKEN_ACTIVE'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
            letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
