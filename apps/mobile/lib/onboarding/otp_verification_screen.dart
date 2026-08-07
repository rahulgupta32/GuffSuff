import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../auth/staging_otp_service.dart';
import '../core/branding/app_theme.dart';
import '../core/l10n/app_strings.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController(
    text: '123456',
  );
  bool isLoading = false;
  String? errorMessage;
  int secondsRemaining = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    timer?.cancel();
    setState(() => secondsRemaining = 60);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final authState = ref.read(authProvider);
    final phone = authState.phoneNumber ?? '+977 9800000000';
    final challenge = authState.challengeId ?? 'dev_challenge';

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final otpService = StagingOtpService();
    final result = await otpService.verifyOtp(
      phone,
      challenge,
      otpController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result.success) {
      ref
          .read(authProvider.notifier)
          .setVerified(
            accessToken: result.accessToken!,
            userId: result.userId!,
            deviceId: result.deviceId!,
          );
      if (mounted) {
        context.go('/onboarding/profile');
      }
    } else {
      setState(() {
        errorMessage = result.message ?? 'Verification failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.verifyOtpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${strings.otpSentTo} ${authState.phoneNumber ?? '+977 9800000000'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_outlined, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.devOtpNotice,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: secondsRemaining == 0 ? startResendTimer : null,
                  child: Text(
                    secondsRemaining > 0
                        ? '${strings.resendIn} ${secondsRemaining}s'
                        : strings.resendOtp,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleVerify,
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
