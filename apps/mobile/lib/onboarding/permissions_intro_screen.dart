import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class PermissionsIntroScreen extends StatelessWidget {
  const PermissionsIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Permissions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Requested Permissions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'GuffSuff requests permissions only when explicitly needed for product features.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 32),
              _buildPermissionTile(
                icon: Icons.contacts_outlined,
                title: 'Contacts Discovery (Optional)',
                description:
                    'Used only to find friends on GuffSuff. Address book is never uploaded without explicit consent.',
              ),
              const SizedBox(height: 20),
              _buildPermissionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Encrypted Notifications',
                description:
                    'Delivers privacy-preserving push wake-ups when new messages arrive.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Enter GuffSuff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryNavy, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
