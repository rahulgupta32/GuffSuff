import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class PrivacyExplainScreen extends StatelessWidget {
  const PrivacyExplainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 48,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                strings.privacyExplainTitle,
                style: AppTypography.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                strings.privacyExplainBody,
                style: AppTypography.bodyLarge.copyWith(
                  color:
                      isDark
                          ? AppColors.darkContentSecondary
                          : AppColors.lightContentSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/phone-entry'),
                  child: Text(strings.continueButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
