import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController(text: 'Rahul Gupta');
  final _usernameController = TextEditingController(text: 'rahul_g');
  final _bioController = TextEditingController(
    text: 'Building GuffSuff for Nepal 🇳🇵',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          children: [
            Text(
              strings.setupProfile,
              style: AppTypography.display.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSpacing.s24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: strings.displayName,
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: strings.username,
                prefixText: '@',
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: strings.bioStatus,
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/chats'),
                child: Text(strings.completeProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
