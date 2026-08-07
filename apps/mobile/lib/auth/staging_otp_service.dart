import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class OtpRequestResult {
  final bool success;
  final String? challengeId;
  final String? message;
  final bool isDevelopmentMode;

  OtpRequestResult({
    required this.success,
    this.challengeId,
    this.message,
    this.isDevelopmentMode = false,
  });
}

class OtpVerifyResult {
  final bool success;
  final String? accessToken;
  final String? userId;
  final String? deviceId;
  final String? message;

  OtpVerifyResult({
    required this.success,
    this.accessToken,
    this.userId,
    this.deviceId,
    this.message,
  });
}

class StagingOtpService {
  final http.Client _client;

  StagingOtpService({http.Client? client}) : _client = client ?? http.Client();

  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    if (AppConfig.environment == AppEnvironment.production) {
      try {
        final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/otp/request');
        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phoneNumber': phoneNumber}),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return OtpRequestResult(
            success: true,
            challengeId: data['challengeId'],
            message: 'OTP sent successfully',
          );
        }
      } catch (_) {}
      return OtpRequestResult(
        success: false,
        message: 'Failed to request OTP from server',
      );
    }

    // Development / Staging / Internal Mode
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/otp/request');
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OtpRequestResult(
          success: true,
          challengeId:
              data['challengeId'] ??
              'srv-challenge-${DateTime.now().millisecondsSinceEpoch}',
          message: 'OTP sent successfully',
        );
      }
    } catch (_) {
      // Offline fallback in non-production environments
    }

    if (AppConfig.allowDevelopmentOtp && AppConfig.developmentOtpCode != null) {
      return OtpRequestResult(
        success: true,
        challengeId: 'dev-challenge-${DateTime.now().millisecondsSinceEpoch}',
        message:
            'DEVELOPMENT OTP MODE — Use code: ${AppConfig.developmentOtpCode}',
        isDevelopmentMode: true,
      );
    }

    return OtpRequestResult(success: false, message: 'Failed to request OTP');
  }

  Future<OtpVerifyResult> verifyOtp(
    String phoneNumber,
    String challengeId,
    String otpCode,
  ) async {
    if (AppConfig.environment == AppEnvironment.production) {
      try {
        final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/otp/verify');
        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'phoneNumber': phoneNumber,
                'challengeId': challengeId,
                'otpCode': otpCode,
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return OtpVerifyResult(
            success: true,
            accessToken: data['accessToken'],
            userId: data['userId'],
            deviceId: data['deviceId'],
          );
        }
      } catch (_) {}
      return OtpVerifyResult(
        success: false,
        message: 'OTP verification failed',
      );
    }

    // Development / Staging / Internal Mode
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/otp/verify');
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phoneNumber': phoneNumber,
              'challengeId': challengeId,
              'otpCode': otpCode,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OtpVerifyResult(
          success: true,
          accessToken: data['accessToken'] ?? 'demo_access_token',
          userId: data['userId'] ?? 'user_dev_001',
          deviceId: data['deviceId'] ?? 'dev_android_emulator',
        );
      }
    } catch (_) {}

    if (AppConfig.allowDevelopmentOtp &&
        AppConfig.developmentOtpCode != null &&
        otpCode == AppConfig.developmentOtpCode) {
      return OtpVerifyResult(
        success: true,
        accessToken:
            'demo_dev_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'usr_nepal_${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
        deviceId: 'dev_android_${Platform.operatingSystem}',
      );
    }

    return OtpVerifyResult(
      success: false,
      message: 'Invalid verification code.',
    );
  }
}
