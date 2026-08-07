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
                'Nepal-First Secure Messaging',
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
              const SizedBox(height: 32),
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
                      trailing: Text('${AppConfig.buildNumber}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Commit SHA'),
                      trailing: Text(
                        AppConfig.commitSha,
                        style: const TextStyle(fontFamily: 'monospace'),
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
