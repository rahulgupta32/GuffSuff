import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/secure_storage.dart';

class MemoryStorage extends SecureStorageService {
  Map<String, dynamic>? saved;
  @override
  Future<String?> getInstallationId() async => 'installation-test';
  @override
  Future<void> saveSession(Map<String, dynamic> value) async {
    saved = value;
  }

  @override
  Future<Map<String, dynamic>?> getSession() async => saved;
  @override
  Future<void> clearSession() async {
    saved = null;
  }
}

const id = '018f3a2b-1234-7000-8000-000000000001';
RegistrationChallenge challenge({bool verified = false}) =>
    RegistrationChallenge(
      phoneNumber: '+9779841234567',
      challengeId: id,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAvailableAt: DateTime.now().add(const Duration(seconds: 60)),
      verified: verified,
    );
Map<String, dynamic> tokens() => {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'sessionId': 'session',
  'deviceId': 'device',
  'userId': 'user',
};
void main() {
  test(
    'request includes required metadata and retains server challenge',
    () async {
      final session = AuthSession(
        storage: MemoryStorage(),
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/otp/request');
          final body = jsonDecode(request.body);
          expect(body['phoneNumber'], '+9779841234567');
          for (final key in [
            'installationId',
            'deviceName',
            'platform',
            'appVersion',
            'osVersion',
          ]) {
            expect(body[key], isNotEmpty);
          }
          return http.Response(
            jsonEncode({
              'challengeId': id,
              'expiresAt': challenge().expiresAt.toIso8601String(),
              'resendAvailableAt':
                  challenge().resendAvailableAt.toIso8601String(),
            }),
            200,
          );
        }),
      );
      expect((await session.requestOtp('९८४१२३४५६७')).challengeId, id);
      expect(session.isAuthenticated, isFalse);
    },
  );
  test('HTTP 200 with success false does not verify or authenticate', () async {
    final session = AuthSession(
      storage: MemoryStorage(),
      client: MockClient((request) async {
        expect(jsonDecode(request.body)['otpCode'], '123456');
        expect(jsonDecode(request.body)['challengeId'], id);
        expect(jsonDecode(request.body).containsKey('code'), isFalse);
        return http.Response('{"success":false}', 200);
      }),
    );
    await expectLater(
      session.verifyOtp(challenge(), '१२३४५६'),
      throwsA(isA<AuthFailure>()),
    );
    expect(session.isAuthenticated, isFalse);
  });
  test(
    'registration persists session only after valid server response',
    () async {
      final storage = MemoryStorage();
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/register');
          expect(
            jsonDecode(request.body)['phoneNumber'],
            challenge().phoneNumber,
          );
          return http.Response(jsonEncode(tokens()), 201);
        }),
      );
      await session.register(
        challenge(verified: true),
        'Test User',
        'test_user',
        accepted: true,
      );
      expect(session.isAuthenticated, isTrue);
      expect(storage.saved?['refreshToken'], 'refresh');
    },
  );
  test(
    'unverified challenge and absent consent never contact server',
    () async {
      var requests = 0;
      final session = AuthSession(
        storage: MemoryStorage(),
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        session.register(challenge(), 'Test User', 'test_user', accepted: true),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        session.register(
          challenge(verified: true),
          'Test User',
          'test_user',
          accepted: false,
        ),
        throwsA(isA<AuthFailure>()),
      );
      expect(requests, 0);
    },
  );
  test('malformed server session fails closed', () async {
    final storage = MemoryStorage();
    final session = AuthSession(
      storage: storage,
      client: MockClient((_) async => http.Response('{}', 201)),
    );
    await expectLater(
      session.register(
        challenge(verified: true),
        'Test User',
        'test_user',
        accepted: true,
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(storage.saved, isNull);
    expect(session.isAuthenticated, isFalse);
  });
  test('restore serializes refresh and logout clears the session', () async {
    var refreshes = 0;
    final storage = MemoryStorage()..saved = tokens();
    final session = AuthSession(
      storage: storage,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/refresh')) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response(
            jsonEncode({...tokens(), 'refreshToken': 'new-refresh'}),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    await session.restore();
    expect(session.isAuthenticated, isTrue);
    await Future.wait([
      session.refresh(),
      session.refresh(),
      session.refresh(),
    ]);
    expect(refreshes, 2);
    await session.logout();
    expect(storage.saved, isNull);
    expect(session.isAuthenticated, isFalse);
  });
  test('failed restore never unlocks authenticated routes', () async {
    final storage = MemoryStorage()..saved = tokens();
    final session = AuthSession(
      storage: storage,
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await session.restore();
    expect(session.isAuthenticated, isFalse);
  });
  test(
    'existing-account login uses verified challenge and persists tokens',
    () async {
      final storage = MemoryStorage();
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/login');
          final body = jsonDecode(request.body);
          expect(body['registrationLockPin'], '654321');
          expect(body['challengeId'], id);
          return http.Response(
            jsonEncode({...tokens(), 'registrationRequired': false}),
            200,
          );
        }),
      );
      expect(
        await session.login(challenge(verified: true), pin: '६५४३२१'),
        isTrue,
      );
      expect(session.isAuthenticated, isTrue);
      expect(storage.saved?['userId'], 'user');
    },
  );
  test('new-user login result does not create a session', () async {
    final storage = MemoryStorage();
    final session = AuthSession(
      storage: storage,
      client: MockClient(
        (_) async => http.Response('{"registrationRequired":true}', 200),
      ),
    );
    expect(await session.login(challenge(verified: true)), isFalse);
    expect(session.isAuthenticated, isFalse);
    expect(storage.saved, isNull);
  });
  test('PIN rejection never persists credentials', () async {
    final storage = MemoryStorage();
    final session = AuthSession(
      storage: storage,
      client: MockClient(
        (_) async => http.Response('{"errorCode":"PIN_INVALID"}', 401),
      ),
    );
    await expectLater(
      session.login(challenge(verified: true), pin: '123456'),
      throwsA(isA<AuthFailure>()),
    );
    expect(storage.saved, isNull);
    expect(session.isAuthenticated, isFalse);
  });
}
