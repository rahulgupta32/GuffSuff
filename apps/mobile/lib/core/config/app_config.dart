enum AppEnvironment { development, staging, production }

class AppConfig {
  static const AppEnvironment environment = AppEnvironment.staging;
  static const String appVersion = '0.1.0';
  static const int buildNumber = 1;
  static const String commitSha = '0d231685';
  static const bool isInternalDemo = true;

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.development:
        return 'http://10.0.2.2:3000';
      case AppEnvironment.staging:
        return 'http://10.0.2.2:3000'; // Default emulator endpoint to local NestJS staging API
      case AppEnvironment.production:
        throw UnsupportedError(
          'Production environment is disabled in this internal demo build.',
        );
    }
  }

  static String get wsBaseUrl {
    switch (environment) {
      case AppEnvironment.development:
        return 'ws://10.0.2.2:3000';
      case AppEnvironment.staging:
        return 'ws://10.0.2.2:3000';
      case AppEnvironment.production:
        throw UnsupportedError(
          'Production environment is disabled in this internal demo build.',
        );
    }
  }
}
