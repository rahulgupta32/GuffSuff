// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'package:flutter/material.dart';

import '../core/branding/app_theme.dart';
import '../core/config/app_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About GuffSuff')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GuffSuff',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nepal-First Messaging Platform',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'INTERNAL DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Version'),
                      trailing: Text(AppConfig.appVersion),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Build Number'),
                      trailing: Text(AppConfig.buildNumber.toString()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Git Commit'),
                      trailing: Text(
                        AppConfig.commitSha,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Environment'),
                      trailing: Text(AppConfig.environment.name.toUpperCase()),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      title: Text('Crypto Provider'),
                      trailing: Text(
                        'UNAVAILABLE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('OTP Mode'),
                      trailing: Text(
                        AppConfig.allowDevelopmentOtp
                            ? 'DEVELOPMENT (${AppConfig.developmentOtpCode})'
                            : 'PRODUCTION',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Backend API'),
                      trailing: Text(
                        AppConfig.apiBaseUrl,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                '© 2026 GuffSuff Team 🇳🇵. All rights reserved.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
