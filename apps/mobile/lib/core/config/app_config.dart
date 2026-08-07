enum AppEnvironment { development, staging, internal, production }

class AppConfig {
  static const AppEnvironment environment = AppEnvironment.staging;
  static const String appVersion = '0.1.0';
  static const int buildNumber = 1;
  static const String commitSha = 'ecc14f0b';
  static const bool isInternalDemo = true;

  static bool get allowDevelopmentOtp {
    if (environment == AppEnvironment.production) {
      if (isInternalDemo) {
        throw StateError(
          'CRITICAL SECURITY ERROR: isInternalDemo cannot be true in production environment.',
        );
      }
      return false;
    }
    return true;
  }

  static String? get developmentOtpCode {
    if (!allowDevelopmentOtp || environment == AppEnvironment.production) {
      return null;
    }
    return '123456';
  }

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.development:
      case AppEnvironment.staging:
      case AppEnvironment.internal:
        return 'http://10.0.2.2:3000';
      case AppEnvironment.production:
        throw UnsupportedError(
          'Production environment is disabled in this internal demo build.',
        );
    }
  }

  static String get wsBaseUrl {
    switch (environment) {
      case AppEnvironment.development:
      case AppEnvironment.staging:
      case AppEnvironment.internal:
        return 'ws://10.0.2.2:3000';
      case AppEnvironment.production:
        throw UnsupportedError(
          'Production environment is disabled in this internal demo build.',
        );
    }
  }
}
