import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class OtpResult {
  final bool success;
  final String? challengeId;
  final String? accessToken;
  final String? userId;
  final String? deviceId;
  final String? message;

  OtpResult({
    required this.success,
    this.challengeId,
    this.accessToken,
    this.userId,
    this.deviceId,
    this.message,
  });
}

abstract class OtpProvider {
  Future<OtpResult> requestOtp(String phoneNumber);
  Future<OtpResult> verifyOtp(
    String phoneNumber,
    String challengeId,
    String code,
  );
  Future<OtpResult> resendOtp(String phoneNumber, String challengeId);
}

class DevelopmentOtpProvider implements OtpProvider {
  DevelopmentOtpProvider() {
    if (AppConfig.isProduction) {
      throw StateError(
        'FATAL: DevelopmentOtpProvider instantiated in PRODUCTION build.',
      );
    }
  }

  @override
  Future<OtpResult> requestOtp(String phoneNumber) async {
    return OtpResult(
      success: true,
      challengeId: 'dev_challenge_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Development OTP code is 123456',
    );
  }

  @override
  Future<OtpResult> verifyOtp(
    String phoneNumber,
    String challengeId,
    String code,
  ) async {
    if (code == AppConfig.developmentOtpCode) {
      return OtpResult(
        success: true,
        accessToken: 'dev_mock_access_token_123456',
        userId: 'u_dev_nepal_user',
        deviceId: 'dev_device_android',
      );
    }
    return OtpResult(
      success: false,
      message: 'Invalid OTP code. Please use 123456 in dev mode.',
    );
  }

  @override
  Future<OtpResult> resendOtp(String phoneNumber, String challengeId) async {
    return requestOtp(phoneNumber);
  }
}

class ProductionOtpProvider implements OtpProvider {
  final String baseUrl;

  ProductionOtpProvider({required this.baseUrl});

  @override
  Future<OtpResult> requestOtp(String phoneNumber) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/otp/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return OtpResult(
          success: true,
          challengeId: body['challengeId'] ?? 'srv_challenge',
        );
      }
    } catch (e) {
      return OtpResult(
        success: false,
        message: 'Network error connecting to auth server.',
      );
    }
    return OtpResult(
      success: false,
      message: 'Failed to request OTP from server.',
    );
  }

  @override
  Future<OtpResult> verifyOtp(
    String phoneNumber,
    String challengeId,
    String code,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'challengeId': challengeId,
          'code': code,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return OtpResult(
          success: true,
          accessToken: body['accessToken'],
          userId: body['user']?['id'],
          deviceId: body['device']?['id'],
        );
      }
    } catch (e) {
      return OtpResult(success: false, message: 'Network error verifying OTP.');
    }
    return OtpResult(success: false, message: 'Invalid verification code.');
  }

  @override
  Future<OtpResult> resendOtp(String phoneNumber, String challengeId) async {
    return requestOtp(phoneNumber);
  }
}
