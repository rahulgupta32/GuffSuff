import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:guffsuff_mobile/crypto/android_direct_crypto.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'package:guffsuff_mobile/services/direct_message_recovery.dart';
import 'prekey_api_test.dart' as fixture;
import 'auth_session_test.dart' show challenge;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('guffsuff/native_identity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AuthSession session;
  late AndroidDirectCrypto crypto;
  DirectCryptoRoute route({bool incoming = false, bool expired = false}) =>
      DirectCryptoRoute(
        conversationId: fixture.conversation,
        senderUserId: incoming ? fixture.peer : fixture.user,
        senderDeviceId: incoming ? fixture.target : fixture.device,
        recipientUserId: incoming ? fixture.user : fixture.peer,
        recipientDeviceId: incoming ? fixture.device : fixture.target,
        createdAtMillis:
            fixture.now
                .subtract(const Duration(hours: 2))
                .millisecondsSinceEpoch,
        expiresAtMillis:
            fixture.now
                .add(Duration(hours: expired ? -1 : 1))
                .millisecondsSinceEpoch,
      );
  final wire = base64Encode(List.filled(13, 1));
  final fingerprint = base64Encode(List.filled(32, 2));
  Map<String, dynamic> saved({bool expired = false}) => {
    'messageId': fixture.retry,
    'route': route(expired: expired).json,
    'batchFingerprintBase64': fingerprint,
    'deviceEnvelopes': [
      {'recipientDeviceId': fixture.target, 'opaquePayloadBase64': wire},
    ],
  };
  Map<String, dynamic> history({bool incoming = false}) => {
    'recordId': incoming ? fixture.conversation : fixture.retry,
    'direction': incoming ? 'incoming' : 'outgoing',
    'messageId': fixture.retry,
    'route': route(incoming: incoming).json,
    'text': 'नमस्ते history',
    'isAccepted': true,
    'serverEnvelopeId': incoming ? fixture.conversation : null,
  };
  Map<String, dynamic> accepted() => {
    ...fixture.accepted(),
    'payload_byte_length': 13,
  };
  Map<String, dynamic> pending() => {
    ...fixture.pending(),
    'payload_byte_length': 13,
    'opaque_payload_base64': wire,
    'client_created_at':
        DateTime.fromMillisecondsSinceEpoch(
          route(incoming: true).createdAtMillis,
          isUtc: true,
        ).toIso8601String(),
  };
  Future<void> signIn(
    Future<http.Response> Function(http.Request) handler,
  ) async {
    session = await fixture.signIn(handler);
    crypto = AndroidDirectCrypto(session, clock: () => fixture.now);
  }

  DirectMessageRecoveryCoordinator coordinator() =>
      DirectMessageRecoveryCoordinator(
        crypto,
        EnvelopeApi(session),
        clock: () => fixture.now,
      );
  setUp(() async {
    await signIn((_) async => throw StateError('Unexpected HTTP'));
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    session.dispose();
  });

  test(
    'saved batches are immutable and acceptance binds exact native fingerprint',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pendingDirectMessages') {
          expect(call.arguments['conversationId'], fixture.conversation);
          return {
            'pending': [saved()],
          };
        }
        expect(call.method, 'markDirectMessageAccepted');
        expect(call.arguments['batchFingerprintBase64'], fingerprint);
        expect(call.arguments['messageId'], fixture.retry);
        expect(call.arguments['serverEnvelopeId'], fixture.conversation);
        return {
          'messageId': fixture.retry,
          'serverEnvelopeId': fixture.conversation,
          'isAccepted': true,
        };
      });
      final batches = await crypto.pending(fixture.conversation);
      expect(batches.single.ciphertexts[fixture.target], List.filled(13, 1));
      expect(() => batches.clear(), throwsUnsupportedError);
      expect(() => batches.single.ciphertexts.clear(), throwsUnsupportedError);
      expect(
        () => batches.single.ciphertexts[fixture.target]![0] = 0,
        throwsUnsupportedError,
      );
      await crypto.accepted(batches.single, fixture.conversation);
    },
  );

  test(
    'saved batch parser rejects private fields, duplicates, scope and inventory mismatches',
    () async {
      final wrongScope = {...route().json, 'senderUserId': fixture.peer};
      final bad = <dynamic>[
        [saved(), saved()],
        [
          {...saved(), 'privateState': 'forbidden'},
        ],
        [
          {...saved(), 'route': wrongScope},
        ],
        [
          {...saved(), 'batchFingerprintBase64': wire},
        ],
        [
          {...saved(), 'deviceEnvelopes': []},
        ],
        [
          {
            ...saved(),
            'deviceEnvelopes': [
              saved()['deviceEnvelopes'][0],
              saved()['deviceEnvelopes'][0],
            ],
          },
        ],
        [
          {
            ...saved(),
            'deviceEnvelopes': [
              {'recipientDeviceId': fixture.peer, 'opaquePayloadBase64': wire},
            ],
          },
        ],
      ];
      for (final response in bad) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {'pending': response},
        );
        await expectLater(
          crypto.pending(fixture.conversation),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'history accepts legacy null mappings and distinct incoming record/message IDs',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'history': [history(), history(incoming: true)],
        },
      );
      final rows = await crypto.history(fixture.conversation);
      expect(rows.first.serverEnvelopeId, isNull);
      expect(rows.last.recordId, fixture.conversation);
      expect(rows.last.message.messageId, fixture.retry);
      expect(rows.last.message.text, 'नमस्ते history');
      expect(() => rows.clear(), throwsUnsupportedError);
    },
  );

  test(
    'history rejects wrong direction, scope, receipts, duplicate records and private data',
    () async {
      for (final rows in [
        [history(), history()],
        [
          {...history(), 'direction': 'unknown'},
        ],
        [
          {...history(), 'isAccepted': false, 'serverEnvelopeId': fixture.peer},
        ],
        [
          {...history(incoming: true), 'serverEnvelopeId': fixture.retry},
        ],
        [
          {...history(), 'recordId': fixture.peer},
        ],
        [
          {...history(), 'text': ''},
        ],
        [
          {...history(), 'privateState': 'forbidden'},
        ],
      ]) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {'history': rows},
        );
        await expectLater(
          crypto.history(fixture.conversation),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'retry submits original inventory and ciphertext before native acceptance',
    () async {
      session.dispose();
      final events = <String>[];
      await signIn((request) async {
        events.add('http-submit');
        expect(
          request.url.path,
          '/api/v1/conversations/${fixture.conversation}/device-envelopes',
        );
        final body = jsonDecode(request.body);
        expect(body['idempotencyKey'], fixture.retry);
        expect(body['deviceEnvelopes'], saved()['deviceEnvelopes']);
        expect(
          body['clientCreatedAt'],
          DateTime.fromMillisecondsSinceEpoch(
            route().createdAtMillis,
            isUtc: true,
          ).toIso8601String(),
        );
        return http.Response(jsonEncode(accepted()), 200);
      });
      messenger.setMockMethodCallHandler(channel, (call) async {
        events.add(call.method);
        if (call.method == 'pendingDirectMessages') {
          return {
            'pending': [saved()],
          };
        }
        return {
          'messageId': fixture.retry,
          'serverEnvelopeId': fixture.retry,
          'isAccepted': true,
        };
      });
      expect(await coordinator().retryPending(fixture.conversation), 1);
      expect(events, [
        'pendingDirectMessages',
        'http-submit',
        'markDirectMessageAccepted',
      ]);
    },
  );

  test(
    'lost local acceptance retries identical ciphertext without encryption',
    () async {
      session.dispose();
      final bodies = <String>[];
      await signIn((request) async {
        bodies.add(request.body);
        return http.Response(jsonEncode(accepted()), 200);
      });
      var acknowledgements = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pendingDirectMessages') {
          return {
            'pending': [saved()],
          };
        }
        expect(call.method, 'markDirectMessageAccepted');
        if (++acknowledgements == 1) {
          throw PlatformException(code: 'UNAVAILABLE');
        }
        return {
          'messageId': fixture.retry,
          'serverEnvelopeId': fixture.retry,
          'isAccepted': true,
        };
      });
      final recovery = coordinator();
      await expectLater(
        recovery.retryPending(fixture.conversation),
        throwsA(isA<CryptoBridgeFailure>()),
      );
      expect(await recovery.retryPending(fixture.conversation), 1);
      expect(bodies.length, 2);
      expect(bodies[0], bodies[1]);
    },
  );

  test(
    'expired entries remain saved and are not submitted or marked accepted',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pendingDirectMessages');
        return {
          'pending': [saved(expired: true)],
        };
      });
      expect(await coordinator().retryPending(fixture.conversation), 0);
      expect(
        (await crypto.pending(fixture.conversation)).single.messageId,
        fixture.retry,
      );
    },
  );

  test(
    'mismatched HTTP acceptance cannot mark a native batch accepted',
    () async {
      session.dispose();
      await signIn(
        (_) async => http.Response(
          jsonEncode({...accepted(), 'recipient_user_id': fixture.user}),
          200,
        ),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pendingDirectMessages');
        return {
          'pending': [saved()],
        };
      });
      await expectLater(
        coordinator().retryPending(fixture.conversation),
        throwsFormatException,
      );
    },
  );

  test(
    'receive commits verified history before receipt and retries failed receipts',
    () async {
      session.dispose();
      final events = <String>[];
      var receipts = 0;
      await signIn((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([pending()]), 200);
        }
        events.add('http-delivered');
        expect(
          request.url.path,
          '/api/v1/envelopes/${fixture.retry}/delivered',
        );
        return http.Response('{}', ++receipts == 1 ? 500 : 200);
      });
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'receiveDirectMessage');
        events.add('native-verified-history');
        return {
          'messageId': fixture.conversation,
          'route': call.arguments['route'],
          'text': 'verified',
        };
      });
      final recovery = coordinator();
      await expectLater(
        recovery.receivePending(fixture.conversation),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        (await recovery.receivePending(fixture.conversation)).single.messageId,
        fixture.conversation,
      );
      expect(events, [
        'native-verified-history',
        'http-delivered',
        'native-verified-history',
        'http-delivered',
      ]);
    },
  );

  test(
    'native routing mismatch prevents HTTP delivery acknowledgement',
    () async {
      session.dispose();
      await signIn((request) async {
        expect(request.method, 'GET');
        return http.Response(jsonEncode([pending()]), 200);
      });
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'messageId': fixture.retry,
          'route': {
            ...call.arguments['route'] as Map,
            'conversationId': fixture.peer,
          },
          'text': 'wrong route',
        },
      );
      await expectLater(
        coordinator().receivePending(fixture.conversation),
        throwsFormatException,
      );
    },
  );

  test(
    'logout while native recovery is pending suppresses HTTP and concurrent runs',
    () async {
      final started = Completer<void>();
      final response = Completer<dynamic>();
      messenger.setMockMethodCallHandler(channel, (_) async {
        started.complete();
        return response.future;
      });
      final recovery = coordinator();
      final pending = recovery.retryPending(fixture.conversation);
      final assertion = expectLater(pending, throwsA(isA<AuthFailure>()));
      await started.future;
      await expectLater(
        recovery.receivePending(fixture.conversation),
        throwsStateError,
      );
      await session.logout();
      response.complete({
        'pending': [saved()],
      });
      await assertion;
    },
  );

  test('changed session ID rejects stale recovery', () async {
    session.dispose();
    await signIn((request) async {
      expect(request.url.path, '/api/v1/auth/login');
      return http.Response(
        jsonEncode({
          ...fixture.tokens(),
          'sessionId': 'replacement',
          'registrationRequired': false,
        }),
        200,
      );
    });
    final started = Completer<void>();
    final response = Completer<dynamic>();
    messenger.setMockMethodCallHandler(channel, (_) async {
      started.complete();
      return response.future;
    });
    final pending = coordinator().retryPending(fixture.conversation);
    final assertion = expectLater(pending, throwsA(isA<AuthFailure>()));
    await started.future;
    expect(await session.login(challenge(verified: true)), isTrue);
    response.complete({
      'pending': [saved()],
    });
    await assertion;
  });
}
