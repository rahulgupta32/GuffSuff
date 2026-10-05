import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, internal, production }

class AppConfig {
  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
  static AppEnvironment get environment => AppEnvironment.values.firstWhere(
    (value) => value.name == _environment,
    orElse: () => throw StateError('Unknown APP_ENV'),
  );
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? '' : 'http://10.0.2.2:3000',
  );
  static bool get isProduction =>
      kReleaseMode || environment == AppEnvironment.production;
  static bool get allowDevelopmentOtp =>
      !isProduction && environment == AppEnvironment.internal;
  static void validate() {
    final selectedEnvironment = environment;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path.isNotEmpty ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        ((isProduction || selectedEnvironment == AppEnvironment.staging) &&
            uri.scheme != 'https')) {
      throw StateError(
        'API_BASE_URL must be an origin; HTTPS is required in staging and production.',
      );
    }
  }
}
