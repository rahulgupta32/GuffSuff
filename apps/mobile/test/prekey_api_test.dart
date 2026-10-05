import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/prekey_api.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'auth_session_test.dart' show MemoryStorage;

const user = '018f3a2b-1234-7000-8000-000000000001';
const device = '018f3a2b-1234-7000-8000-000000000002';
const peer = '018f3a2b-1234-7000-8000-000000000003';
const target = '018f3a2b-1234-7000-8000-000000000004';
const conversation = '018f3a2b-1234-7000-8000-000000000005';
const retry = '018f3a2b-1234-7000-8000-000000000006';
final now = DateTime.utc(2026, 10, 5);
Map<String, dynamic> tokens() => {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'sessionId': 'session',
  'userId': user,
  'deviceId': device,
};
String curve(int suffix) => base64Encode([5, ...List.filled(31, 0), suffix]);
Map<String, dynamic> bundle({bool claim = false}) => {
  'protocolVersion': 2,
  'registrationId': 123,
  'identityPublicKeyBase64': curve(1),
  'signedPrekeyId': 1,
  'signedPrekeyPublicBase64': curve(2),
  'signedPrekeySignatureBase64': base64Encode(List.filled(64, 1)),
  'kemPrekeyId': 1,
  'kemPrekeyPublicBase64': base64Encode([1, 2, 3]),
  'kemPrekeySignatureBase64': base64Encode(List.filled(64, 2)),
  'expiresAt': now.add(const Duration(days: 28)).toIso8601String(),
  if (claim) ...{
    'deviceId': target,
    'oneTimePrekeyId': 1,
    'oneTimePrekeyPublicBase64': curve(3),
  } else
    'oneTimePrekeys': [
      {'keyId': 1, 'publicKeyBase64': curve(3)},
    ],
};
Future<AuthSession> signIn(
  Future<http.Response> Function(http.Request) handler,
) async {
  final session = AuthSession(
    storage: MemoryStorage()..saved = tokens(),
    client: MockClient(
      (request) async =>
          request.url.path.endsWith('/refresh')
              ? http.Response(jsonEncode(tokens()), 200)
              : handler(request),
    ),
    baseUrl: 'https://api.example.test',
  );
  await session.restore();
  return session;
}

Map<String, dynamic> accepted() => {
  'id': retry,
  'conversation_id': conversation,
  'sender_user_id': user,
  'sender_device_id': device,
  'recipient_user_id': peer,
  'protocol_version': 2,
  'payload_mode': 'per_device',
  'payload_byte_length': 3,
  'recipientDeviceCount': 1,
  'idempotentRetry': false,
  'expires_at': now.add(const Duration(hours: 1)).toIso8601String(),
};
Map<String, dynamic> pending() => {
  'id': retry,
  'conversation_id': conversation,
  'sender_user_id': peer,
  'sender_device_id': target,
  'recipient_user_id': user,
  'protocol_version': 2,
  'delivery_status': 'accepted',
  'payload_byte_length': 3,
  'opaque_payload_base64': 'AQID',
  'client_created_at': now.toIso8601String(),
  'expires_at': now.add(const Duration(hours: 1)).toIso8601String(),
};
void main() {
  test(
    'publishes only validated public material and verifies owning device',
    () async {
      final session = await signIn((request) async {
        expect(request.url.path, '/api/v1/devices/current/prekeys');
        expect(request.headers['Authorization'], 'Bearer access');
        expect(jsonDecode(request.body), bundle());
        return http.Response(
          jsonEncode({'deviceId': device, 'availablePrekeys': 100}),
          200,
        );
      });
      expect(await PrekeyApi(session, clock: () => now).publish(bundle()), 100);
    },
  );
  test(
    'claim retry preserves caller ID and exact body through refresh',
    () async {
      final bodies = <String>[];
      final session = await signIn((request) async {
        expect(
          request.url.path,
          '/api/v1/conversations/$conversation/devices/$target/prekey-claims',
        );
        bodies.add(request.body);
        return bodies.length == 1
            ? http.Response('{}', 401)
            : http.Response(jsonEncode(bundle(claim: true)), 200);
      });
      final result = await PrekeyApi(
        session,
        clock: () => now,
      ).claim(conversationId: conversation, deviceId: target, claimId: retry);
      expect(result.json, bundle(claim: true));
      expect(bodies, [
        jsonEncode({'claimId': retry}),
        jsonEncode({'claimId': retry}),
      ]);
      expect(() => result.json['registrationId'] = 9, throwsUnsupportedError);
    },
  );
  test(
    'malformed public bundles and private fields fail before publication',
    () async {
      var requests = 0;
      final session = await signIn((request) async {
        requests++;
        return http.Response('{}', 200);
      });
      final invalid = <Map<String, dynamic>>[
        {...bundle(), 'privateKey': 'secret'},
        {...bundle(), 'protocolVersion': 1},
        {...bundle(), 'protocolVersion': 2.0},
        {...bundle(), 'registrationId': 0},
        {...bundle(), 'kemPrekeyId': -1},
        {...bundle(), 'identityPublicKeyBase64': curve(1) + '\n'},
        {...bundle(), 'kemPrekeyPublicBase64': ''},
        {...bundle(), 'expiresAt': now.toIso8601String()},
        {...bundle(), 'expiresAt': '2026-02-30T00:00:00Z'},
        {
          ...bundle(),
          'expiresAt': now.add(const Duration(days: 31)).toIso8601String(),
        },
        {
          ...bundle(),
          'oneTimePrekeys': [
            {'keyId': 1, 'publicKeyBase64': curve(3)},
            {'keyId': 1, 'publicKeyBase64': curve(4)},
          ],
        },
        {
          ...bundle(),
          'oneTimePrekeys': [
            {'keyId': 1, 'publicKeyBase64': curve(3)},
            {'keyId': 2, 'publicKeyBase64': curve(3)},
          ],
        },
      ];
      for (final value in invalid) {
        await expectLater(
          PrekeyApi(session, clock: () => now).publish(value),
          throwsFormatException,
        );
      }
      expect(requests, 0);
    },
  );
  test(
    'claim rejects target mismatch and signed-only or legacy responses',
    () async {
      for (final bad in [
        {...bundle(claim: true), 'deviceId': device},
        {...bundle(claim: true), 'oneTimePrekeyId': null},
        {...bundle(claim: true), 'protocolVersion': 1},
      ]) {
        final session = await signIn(
          (request) async => http.Response(jsonEncode(bad), 200),
        );
        await expectLater(
          PrekeyApi(session, clock: () => now).claim(
            conversationId: conversation,
            deviceId: target,
            claimId: retry,
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('recipient discovery validates, sorts and freezes snapshot', () async {
    final session = await signIn((request) async {
      expect(
        request.url.path,
        '/api/v1/conversations/$conversation/recipients/$peer/devices',
      );
      return http.Response(
        jsonEncode([
          {'id': retry},
          {'id': target},
        ]),
        200,
      );
    });
    final devices = await PrekeyApi(
      session,
    ).recipientDevices(conversation, peer);
    expect(devices, [target, retry]);
    expect(() => devices.add(device), throwsUnsupportedError);
  });
  test(
    'discovery rejects empty duplicate excessive and unexpected inventories',
    () async {
      for (final response in [
        [],
        [
          {'id': target},
          {'id': target},
        ],
        [
          {'id': device},
        ],
        [
          {'id': target, 'userId': peer},
        ],
        List.filled(17, {'id': target}),
      ]) {
        final session = await signIn(
          (request) async => http.Response(jsonEncode(response), 200),
        );
        await expectLater(
          PrekeyApi(session).recipientDevices(conversation, peer),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'per-device submissions snapshot bytes and retry the exact body',
    () async {
      final bodies = <String>[];
      final bytes = [1, 2, 3];
      final session = await signIn((request) async {
        expect(
          request.url.path,
          '/api/v1/conversations/$conversation/device-envelopes',
        );
        bodies.add(request.body);
        bytes[0] = 9;
        final body = jsonDecode(request.body);
        expect(body['protocolVersion'], 2);
        expect(body['deviceEnvelopes'], [
          {'recipientDeviceId': target, 'opaquePayloadBase64': 'AQID'},
        ]);
        return bodies.length == 1
            ? http.Response('{}', 401)
            : http.Response(jsonEncode(accepted()), 201);
      });
      expect(
        await EnvelopeApi(session).submitDevices(
          conversationId: conversation,
          recipientUserId: peer,
          messageId: retry,
          ciphertexts: {target: bytes},
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
        retry,
      );
      expect(bodies.first, bodies.last);
    },
  );
  test('changed submission routing cannot become local acceptance', () async {
    for (final bad in [
      {...accepted(), 'sender_device_id': target},
      {...accepted(), 'recipientDeviceCount': 2},
      {...accepted(), 'payload_byte_length': 4},
      {...accepted(), 'protocol_version': 1},
    ]) {
      final session = await signIn(
        (request) async => http.Response(jsonEncode(bad), 201),
      );
      await expectLater(
        EnvelopeApi(session).submitDevices(
          conversationId: conversation,
          recipientUserId: peer,
          messageId: retry,
          ciphertexts: {
            target: [1, 2, 3],
          },
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
        throwsFormatException,
      );
    }
  });
  test(
    'direct pending accepts PostgreSQL LF encoding and does not acknowledge',
    () async {
      final paths = <String>[];
      final session = await signIn((request) async {
        paths.add(request.url.path);
        return http.Response(
          jsonEncode([
            {...pending(), 'opaque_payload_base64': 'AQ\nID'},
          ]),
          200,
        );
      });
      final result = await EnvelopeApi(
        session,
      ).pendingDirect(conversation, now: now);
      expect(result.single.ciphertext, [1, 2, 3]);
      expect(result.single.recipientDeviceId, device);
      expect(paths, ['/api/v1/conversations/$conversation/envelopes/pending']);
      expect(() => result.single.ciphertext.add(4), throwsUnsupportedError);
    },
  );
  test(
    'direct pending rejects routing length expiry protocol and duplicate IDs',
    () async {
      for (final response in [
        [
          {...pending(), 'conversation_id': retry},
        ],
        [
          {...pending(), 'recipient_user_id': peer},
        ],
        [
          {...pending(), 'payload_byte_length': 2},
        ],
        [
          {...pending(), 'protocol_version': 1},
        ],
        [
          {...pending(), 'expires_at': now.toIso8601String()},
        ],
        [pending(), pending()],
      ]) {
        final session = await signIn(
          (request) async => http.Response(jsonEncode(response), 200),
        );
        await expectLater(
          EnvelopeApi(session).pendingDirect(conversation, now: now),
          throwsFormatException,
        );
      }
    },
  );
  test('public operations cannot return responses after logout', () async {
    late AuthSession session;
    session = await signIn((request) async {
      if (request.url.path.endsWith('/logout')) return http.Response('{}', 200);
      await session.logout();
      return http.Response(jsonEncode(bundle(claim: true)), 200);
    });
    await expectLater(
      PrekeyApi(
        session,
        clock: () => now,
      ).claim(conversationId: conversation, deviceId: target, claimId: retry),
      throwsA(isA<AuthFailure>()),
    );
  });
}
