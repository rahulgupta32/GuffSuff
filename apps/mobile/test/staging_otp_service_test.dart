import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/auth/staging_otp_service.dart';
import 'package:guffsuff_mobile/core/config/app_config.dart';
import 'package:guffsuff_mobile/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

void main() {
  group('Development OTP Hardening & Gating Unit Tests', () {
    test('1. Internal build accepts configured development OTP', () async {
      final service = StagingOtpService();
      final result = await service.verifyOtp(
        '+9779800000000',
        'dev-challenge-123',
        '123456',
      );
      expect(result.success, isTrue);
      expect(result.userId, contains('usr_nepal_9779800000000'));
    });

    test('2. Incorrect development OTP is rejected', () async {
      final service = StagingOtpService();
      final result = await service.verifyOtp(
        '+9779800000000',
        'dev-challenge-123',
        '999999',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('Invalid verification code'));
    });

    test(
      '3. Development OTP code is available in staging/internal environment',
      () {
        expect(AppConfig.allowDevelopmentOtp, isTrue);
        expect(AppConfig.developmentOtpCode, equals('123456'));
      },
    );

    test(
      '4. Development OTP notice string contains code in development mode',
      () {
        final strings = AppStrings(const Locale('en'));
        expect(strings.devOtpNotice, contains('123456'));
      },
    );

    test(
      '5. StagingOtpService requestOtp falls back to DEVELOPMENT OTP MODE when offline',
      () async {
        final service = StagingOtpService();
        final result = await service.requestOtp('+9779800000000');
        expect(result.success, isTrue);
        expect(result.isDevelopmentMode, isTrue);
        expect(
          result.message,
          contains('DEVELOPMENT OTP MODE — Use code: 123456'),
        );
      },
    );
  });
}
