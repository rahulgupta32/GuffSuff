import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_config.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../services/otp_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController(text: '123456');
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final OtpProvider provider =
        AppConfig.allowDevelopmentOtp
            ? DevelopmentOtpProvider()
            : ProductionOtpProvider(baseUrl: AppConfig.baseUrl);

    final res = await provider.verifyOtp(
      widget.phoneNumber,
      'challenge_1',
      _otpController.text,
    );

    if (!mounted) return;

    if (res.success) {
      context.push('/profile-setup');
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = res.message ?? 'Verification failed';
      });
    }
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
                strings.verifyOtpTitle,
                style: AppTypography.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${strings.otpSentTo} ${widget.phoneNumber}',
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkContentSecondary
                          : AppColors.lightContentSecondary,
                ),
              ),
              if (AppConfig.allowDevelopmentOtp) ...[
                const SizedBox(height: AppSpacing.s12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppRadii.borderSmall,
                  ),
                  child: Text(
                    strings.devOtpNotice,
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: AppTypography.display.copyWith(letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.borderMedium,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  child:
                      _isVerifying
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(strings.verifyButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
