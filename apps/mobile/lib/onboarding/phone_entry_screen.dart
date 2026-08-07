import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController(text: '9800000000');
  final String _selectedCountryCode = '+977';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
              Text(
                strings.enterPhoneNumber,
                style: AppTypography.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                strings.phoneSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkContentSecondary
                          : AppColors.lightContentSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.darkBorderSubtle
                                : AppColors.lightBorderSubtle,
                      ),
                      borderRadius: AppRadii.borderMedium,
                    ),
                    child: Text(
                      '🇳🇵 $_selectedCountryCode',
                      style: AppTypography.titleSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.titleSmall,
                      decoration: InputDecoration(
                        hintText: strings.phoneNumberLabel,
                        border: const OutlineInputBorder(
                          borderRadius: AppRadii.borderMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final phone =
                        '$_selectedCountryCode${_phoneController.text}';
                    context.push(
                      '/otp-verification?phone=${Uri.encodeComponent(phone)}',
                    );
                  },
                  child: Text(strings.sendCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
