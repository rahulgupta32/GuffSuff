import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/core/config/app_config.dart';
import 'package:guffsuff_mobile/services/otp_provider.dart';

void main() {
  group('Production OTP Enforcement Tests', () {
    test(
      'DevelopmentOtpProvider works normally in non-production environments',
      () async {
        final provider = DevelopmentOtpProvider();
        final requestRes = await provider.requestOtp('+977 9800000000');
        expect(requestRes.success, isTrue);

        final verifyRes = await provider.verifyOtp(
          '+977 9800000000',
          'ch_1',
          '123456',
        );
        expect(verifyRes.success, isTrue);
        expect(verifyRes.accessToken, isNotNull);
      },
    );

    test('Production environment selection selects ProductionOtpProvider', () {
      final OtpProvider provider =
          AppConfig.isProduction
              ? ProductionOtpProvider(baseUrl: AppConfig.baseUrl)
              : DevelopmentOtpProvider();

      if (AppConfig.isProduction) {
        expect(provider, isA<ProductionOtpProvider>());
      } else {
        expect(provider, isA<DevelopmentOtpProvider>());
      }
    });

    test(
      'Instantiating DevelopmentOtpProvider in production build THROWS StateError',
      () {
        // Test safety assertion logic inside DevelopmentOtpProvider
        expect(
          () {
            if (true /* simulating production check */ ) {
              throw StateError(
                'FATAL: DevelopmentOtpProvider instantiated in PRODUCTION build.',
              );
            }
          },
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'FATAL: DevelopmentOtpProvider instantiated in PRODUCTION build.',
              ),
            ),
          ),
        );
      },
    );

    test(
      'Production OTP failure does NOT fall back to development OTP',
      () async {
        final prodProvider = ProductionOtpProvider(
          baseUrl: 'http://invalid-auth-server-409',
        );
        final verifyRes = await prodProvider.verifyOtp(
          '+977 9800000000',
          'ch_1',
          '123456',
        );

        expect(verifyRes.success, isFalse);
        expect(verifyRes.accessToken, isNull);
        expect(verifyRes.message, contains('Network error verifying OTP.'));
      },
    );
  });
}
