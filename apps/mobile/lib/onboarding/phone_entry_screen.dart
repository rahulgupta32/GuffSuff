import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../auth/staging_otp_service.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class CountryOption {
  final String name;
  final String code;
  final String flag;

  const CountryOption({
    required this.name,
    required this.code,
    required this.flag,
  });
}

const List<CountryOption> countries = [
  CountryOption(name: 'Nepal', code: '+977', flag: '🇳🇵'),
  CountryOption(name: 'India', code: '+91', flag: '🇮🇳'),
  CountryOption(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
  CountryOption(name: 'United States', code: '+1', flag: '🇺🇸'),
  CountryOption(name: 'Australia', code: '+61', flag: '🇦🇺'),
];

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  CountryOption selectedCountry = countries[0]; // Nepal default
  final TextEditingController phoneController = TextEditingController(
    text: '9800000000',
  );
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final rawDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length < 7) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please enter a valid phone number.';
      });
      return;
    }

    final fullPhoneNumber = '${selectedCountry.code} $rawDigits';
    final otpService = StagingOtpService();
    final result = await otpService.requestOtp(fullPhoneNumber);

    setState(() {
      isLoading = false;
    });

    if (result.success) {
      ref
          .read(authProvider.notifier)
          .setPhoneNumber(fullPhoneNumber, result.challengeId!);
      if (mounted) {
        context.go('/onboarding/otp');
      }
    } else {
      setState(() {
        errorMessage = result.message ?? 'Failed to send OTP code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.enterPhoneNumber)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.phoneSubtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CountryOption>(
                        value: selectedCountry,
                        items:
                            countries.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.flag} ${c.code}'),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCountry = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: strings.phoneNumberLabel,
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSendOtp,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(strings.sendCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
