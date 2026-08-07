import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../crypto/provider_neutral_boundary.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isProduction) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Diagnostics are disabled in production builds.'),
        ),
      );
    }

    const MobileCryptoProvider activeProvider = UnavailableCryptoProvider();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(AppConfig.environment.name),
          ),
          const Divider(),
          ListTile(
            title: const Text('Crypto Provider State'),
            subtitle: Text(
              activeProvider.isAvailable
                  ? 'AVAILABLE (${activeProvider.queryCapabilities().providerId})'
                  : 'UNAVAILABLE (Fail-closed baseline)',
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('OTP Mode'),
            subtitle: Text(
              AppConfig.allowDevelopmentOtp
                  ? 'Development OTP Mode (123456)'
                  : 'Production SMS OTP Required',
            ),
          ),
        ],
      ),
    );
  }
}
