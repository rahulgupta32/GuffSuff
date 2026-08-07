import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About GuffSuff')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brandPrimary,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text('GuffSuff', style: AppTypography.display),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Version 1.0.0 (Production Release Candidate)',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Terms of Service'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Open Source Licenses'),
          ),
        ],
      ),
    );
  }
}
