import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.brandPrimary,
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(strings.appTitle, style: AppTypography.display),
              const SizedBox(height: AppSpacing.s8),
              Text(
                strings.appTagline,
                style: AppTypography.titleMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkContentSecondary
                          : AppColors.lightContentSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/privacy-explain'),
                  child: Text(strings.getStarted),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
          ),
        ),
      ),
    );
  }
}
