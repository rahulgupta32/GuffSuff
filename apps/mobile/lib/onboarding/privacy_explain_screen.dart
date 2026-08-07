// ignore_for_file: prefer_const_constructors, deprecated_member_use
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
      appBar: AppBar(title: const Text('Privacy & Security Overview')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy-First Architecture',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'GuffSuff is being built with a privacy-first architecture.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CURRENT BUILD SECTION
                      _buildSectionHeader(
                        context,
                        title: 'CURRENT INTERNAL DEMO BUILD',
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.developer_mode_rounded,
                        title: 'Provider-Neutral Architecture',
                        description:
                            'Abstract native boundary prepared for provider integration without hardcoded crypto assumptions.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.phonelink_lock_rounded,
                        title: 'No Production Crypto Provider',
                        description:
                            'Fail-closed crypto boundary state. No unverified third-party protocol engine is enabled.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.block_rounded,
                        title: 'Message Sending Disabled',
                        description:
                            'Secure messaging is not available in this internal build. Message submission is strictly blocked.',
                      ),

                      const SizedBox(height: 28),

                      // FUTURE GOAL SECTION
                      _buildSectionHeader(
                        context,
                        title: 'FUTURE PRODUCTION GOAL',
                        color: AppTheme.primaryNavy,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Audited Provider Integration',
                        description:
                            'Integration of an audited cryptographic provider passing independent security review.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Encrypted Direct Messaging',
                        description:
                            'End-to-end cryptographic confidentiality for one-on-one user conversations.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        icon: Icons.groups_outlined,
                        title: 'Encrypted Groups',
                        description:
                            'Multi-recipient cryptographic group messaging with forward and post-compromise secrecy.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryNavy, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
