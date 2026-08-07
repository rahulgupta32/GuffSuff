enum AppEnvironment { development, staging, internal, production }

class AppConfig {
  static const AppEnvironment environment = AppEnvironment.development;
  static const String developmentOtpCode = '123456';
  static const String baseUrl = 'http://10.0.2.2:3000';

  static bool get isProduction => environment == AppEnvironment.production;

  static bool get allowDevelopmentOtp {
    if (isProduction) {
      return false;
    }
    return environment == AppEnvironment.development ||
        environment == AppEnvironment.internal;
  }
}
