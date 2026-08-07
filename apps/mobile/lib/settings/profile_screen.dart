import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.brandPrimary.withValues(
                    alpha: 0.15,
                  ),
                  child: const Text(
                    'R',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.interactivePrimary,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Display Name'),
            subtitle: const Text('Rahul Gupta'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alternate_email_rounded),
            title: const Text('Username'),
            subtitle: const Text('@rahul_g'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About / Bio'),
            subtitle: const Text('Building GuffSuff for Nepal 🇳🇵'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone Number'),
            subtitle: const Text('+977 ••••• •••••'),
            trailing: const Icon(Icons.lock_outline_rounded, size: 18),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
