import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';
import '../core/config/app_config.dart';

class AuthFailure implements Exception {
  final String message;
  final int? statusCode;
  AuthFailure(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class RegistrationChallenge {
  final String phoneNumber, challengeId;
  final DateTime expiresAt, resendAvailableAt;
  final bool verified;
  const RegistrationChallenge({
    required this.phoneNumber,
    required this.challengeId,
    required this.expiresAt,
    required this.resendAvailableAt,
    this.verified = false,
  });
  RegistrationChallenge markVerified() => RegistrationChallenge(
    phoneNumber: phoneNumber,
    challengeId: challengeId,
    expiresAt: expiresAt,
    resendAvailableAt: resendAvailableAt,
    verified: true,
  );
}

class AuthSession extends ChangeNotifier {
  final http.Client client;
  final SecureStorageService storage;
  final String baseUrl;
  Map<String, dynamic>? _session;
  Future<void>? _refreshInFlight;
  AuthSession({
    http.Client? client,
    SecureStorageService? storage,
    String? baseUrl,
  }) : client = client ?? http.Client(),
       storage = storage ?? SecureStorageService(),
       baseUrl = baseUrl ?? AppConfig.baseUrl;
  bool get isAuthenticated => _session != null;
  String? get accessToken => _session?['accessToken'] as String?;
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl/api/v1/auth/$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthFailure('Cannot connect. Check your connection and try again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure(
        response.statusCode == 429
            ? 'Too many attempts. Please wait.'
            : response.statusCode == 401
            ? 'Verification failed. Check your registration PIN if enabled.'
            : response.statusCode == 403
            ? 'This account or device is unavailable.'
            : 'Request failed. Please try again.',
        statusCode: response.statusCode,
      );
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthFailure('The server returned an invalid response.');
    }
  }

  Future<Map<String, String>> _metadata() async {
    var id = await storage.getInstallationId();
    if (id == null) {
      final random = Random.secure();
      id =
          List.generate(
            32,
            (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join();
      await storage.saveInstallationId(id);
    }
    return {
      'installationId': id,
      'deviceName': 'गफसफ ${defaultTargetPlatform.name}',
      'platform':
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      'appVersion': '0.1.0',
      'osVersion': 'unknown',
    };
  }

  Future<RegistrationChallenge> requestOtp(String input) async {
    final phone = normalizeNepalPhone(input);
    final body = await _post('otp/request', {
      'phoneNumber': phone,
      ...await _metadata(),
    });
    try {
      final id = body['challengeId'] as String;
      if (!RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(id)) {
        throw const FormatException();
      }
      return RegistrationChallenge(
        phoneNumber: phone,
        challengeId: id,
        expiresAt: DateTime.parse(body['expiresAt'] as String),
        resendAvailableAt: DateTime.parse(body['resendAvailableAt'] as String),
      );
    } catch (_) {
      throw AuthFailure('The server returned an invalid challenge.');
    }
  }

  Future<RegistrationChallenge> verifyOtp(
    RegistrationChallenge challenge,
    String code,
  ) async {
    if (!DateTime.now().isBefore(challenge.expiresAt)) {
      throw AuthFailure('Code expired. Request a new code.');
    }
    final asciiCode = asciiDigits(code.trim());
    if (!RegExp(r'^\d{6}$').hasMatch(asciiCode)) {
      throw AuthFailure('Enter the six-digit code.');
    }
    final body = await _post('otp/verify', {
      'challengeId': challenge.challengeId,
      'otpCode': asciiCode,
    });
    if (body['success'] != true ||
        body['challengeId'] != challenge.challengeId) {
      throw AuthFailure('Incorrect code. Please try again.');
    }
    return challenge.markVerified();
  }

  Future<void> register(
    RegistrationChallenge challenge,
    String name,
    String username, {
    required bool accepted,
  }) async {
    if (!accepted) {
      throw AuthFailure('Please accept the terms and privacy policy.');
    }
    if (!challenge.verified || !DateTime.now().isBefore(challenge.expiresAt)) {
      throw AuthFailure('Please verify your phone again.');
    }
    final body = await _post('register', {
      'challengeId': challenge.challengeId,
      'phoneNumber': challenge.phoneNumber,
      ...await _metadata(),
      'displayName': name.trim(),
      'username': username.trim(),
      'locale': 'ne',
      'timezone': 'Asia/Kathmandu',
      'termsAccepted': true,
      'privacyAccepted': true,
    });
    for (final key in [
      'accessToken',
      'refreshToken',
      'sessionId',
      'deviceId',
      'userId',
    ]) {
      if (body[key] is! String || (body[key] as String).isEmpty) {
        throw AuthFailure('The server returned an incomplete session.');
      }
    }
    await storage.saveSession(body);
    _session = body;
    notifyListeners();
  }

  Future<bool> login(RegistrationChallenge challenge, {String? pin}) async {
    if (!challenge.verified || !DateTime.now().isBefore(challenge.expiresAt)) {
      throw AuthFailure('Please verify your phone again.');
    }
    final body = await _post('login', {
      'challengeId': challenge.challengeId,
      'phoneNumber': challenge.phoneNumber,
      ...await _metadata(),
      if (pin != null && pin.trim().isNotEmpty)
        'registrationLockPin': asciiDigits(pin.trim()),
    });
    if (body['registrationRequired'] == true) return false;
    if (body['registrationRequired'] != false) {
      throw AuthFailure('The server returned an invalid login response.');
    }
    for (final key in [
      'accessToken',
      'refreshToken',
      'sessionId',
      'deviceId',
      'userId',
    ]) {
      if (body[key] is! String || (body[key] as String).isEmpty) {
        throw AuthFailure('The server returned an incomplete session.');
      }
    }
    await storage.saveSession(body);
    _session = body;
    notifyListeners();
    return true;
  }

  Future<void> restore() async {
    try {
      final saved = await storage.getSession();
      if (saved == null) return;
      if (saved['refreshToken'] is! String || saved['deviceId'] is! String) {
        await storage.clearSession();
        return;
      }
      _session = saved;
      await refresh();
    } catch (_) {
      _session = null;
    }
    notifyListeners();
  }

  Future<void> refresh() =>
      _refreshInFlight ??= _rotate().whenComplete(
        () => _refreshInFlight = null,
      );
  Future<void> _rotate() async {
    final current = _session;
    if (current == null) throw AuthFailure('Please sign in again.');
    final response = await _post('refresh', {
      'refreshToken': current['refreshToken'],
    });
    for (final key in ['accessToken', 'refreshToken', 'sessionId']) {
      if (response[key] is! String || (response[key] as String).isEmpty) {
        throw AuthFailure('The server returned an incomplete session.');
      }
    }
    if (!identical(_session, current)) return;
    final updated = {...current, ...response};
    await storage.saveSession(updated);
    if (!identical(_session, current)) {
      await storage.clearSession();
      return;
    }
    _session = updated;
    notifyListeners();
  }

  Future<dynamic> getJson(String path) => _authenticatedJson(path);

  Future<dynamic> postJson(String path, Map<String, dynamic> body) =>
      _authenticatedJson(path, body: body);

  Future<dynamic> _authenticatedJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (!isAuthenticated) throw AuthFailure('Please sign in again.');
    final sessionId = _session?['sessionId'];
    void ensureSameSession() {
      if (!isAuthenticated || _session?['sessionId'] != sessionId) {
        throw AuthFailure('The session changed. Please try again.');
      }
    }

    final uri = Uri.parse('$baseUrl/api/v1/$path');
    Future<http.Response> request() {
      ensureSameSession();
      final headers = {'Authorization': 'Bearer $accessToken'};
      if (body == null) {
        return client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      }
      return client
          .post(
            uri,
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    }

    var response = await request();
    if (response.statusCode == 401) {
      try {
        await refresh();
      } on AuthFailure catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          _session = null;
          notifyListeners();
          await storage.clearSession();
        }
        rethrow;
      }
      response = await request();
    }
    ensureSameSession();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure(
        'Unable to complete request. Please try again.',
        statusCode: response.statusCode,
      );
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<void> logout() async {
    final token = accessToken;
    _session = null;
    notifyListeners();
    await storage.clearSession();
    if (token != null) {
      try {
        await _post('logout', {}, token: token);
      } catch (_) {
        /* Local logout remains effective. */
      }
    }
  }
}

String asciiDigits(String value) => value.replaceAllMapped(
  RegExp('[०-९]'),
  (m) => '०१२३४५६७८९'.indexOf(m[0]!).toString(),
);
String normalizeNepalPhone(String input) {
  var phone = asciiDigits(input).replaceAll(RegExp(r'[\s()-]'), '');
  if (!phone.startsWith('+')) phone = '+977$phone';
  if (!RegExp(r'^\+9779\d{9}$').hasMatch(phone)) {
    throw AuthFailure('Enter a valid ten-digit Nepal mobile number.');
  }
  return phone;
}

final authSession = AuthSession();
