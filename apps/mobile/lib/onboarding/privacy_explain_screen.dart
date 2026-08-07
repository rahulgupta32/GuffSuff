import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class PrivacyExplainScreen extends StatelessWidget {
  const PrivacyExplainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Built for Privacy First',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'GuffSuff protects your personal conversations with strict zero-knowledge principles.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 32),
              _buildFeatureRow(
                icon: Icons.lock_outline_rounded,
                title: 'End-to-End Security Architecture',
                description:
                    'Messages are intended for recipient eyes only. No server plaintext storage.',
              ),
              const SizedBox(height: 20),
              _buildFeatureRow(
                icon: Icons.phonelink_erase_rounded,
                title: 'Per-Device Keys',
                description:
                    'Cryptographic identity is anchored directly to your verified physical device.',
              ),
              const SizedBox(height: 20),
              _buildFeatureRow(
                icon: Icons.no_encryption_gmailerrorred_rounded,
                title: 'Internal Demo Mode',
                description:
                    'Real secure messaging is disabled until an audited production provider is approved.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/phone'),
                  child: Text(strings.continueButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryNavy),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
