import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyAccessToken = 'gs_access_token';
  static const String _keyRefreshToken = 'gs_refresh_token';
  static const String _keySessionId = 'gs_session_id';
  static const String _keyDeviceId = 'gs_device_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required String deviceId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keySessionId, value: sessionId);
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  Future<String?> getAccessToken() async =>
      await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: _keyRefreshToken);
  Future<String?> getSessionId() async =>
      await _storage.read(key: _keySessionId);
  Future<String?> getDeviceId() async => await _storage.read(key: _keyDeviceId);

  Future<void> saveSession(Map<String, dynamic> session) =>
      _storage.write(key: 'gs_session_v1', value: jsonEncode(session));
  Future<Map<String, dynamic>?> getSession() async {
    final value = await _storage.read(key: 'gs_session_v1');
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> clearSession() async {
    for (final key in [
      'gs_session_v1',
      _keyAccessToken,
      _keyRefreshToken,
      _keySessionId,
      _keyDeviceId,
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<String?> getInstallationId() =>
      _storage.read(key: 'gs_installation_id');
  Future<void> saveInstallationId(String id) =>
      _storage.write(key: 'gs_installation_id', value: id);

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
