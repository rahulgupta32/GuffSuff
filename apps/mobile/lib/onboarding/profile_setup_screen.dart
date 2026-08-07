import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController(
    text: 'Rahul Gupta',
  );
  final TextEditingController usernameController = TextEditingController(
    text: 'rahul_g',
  );
  final TextEditingController statusController = TextEditingController(
    text: 'Hello GuffSuff! 🇳🇵',
  );

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    statusController.dispose();
    super.dispose();
  }

  void _handleSave() {
    ref
        .read(authProvider.notifier)
        .updateProfile(
          displayName: nameController.text.trim(),
          username: usernameController.text.trim(),
          status: statusController.text.trim(),
        );
    context.go('/onboarding/permissions');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.setupProfile)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryNavy.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          size: 54,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryNavy,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  strings.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Gupta',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(hintText: 'e.g. rahul_g'),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.bioStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(hintText: 'Status update'),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(strings.completeProfile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
