import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/crypto/android_direct_crypto.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'package:guffsuff_mobile/services/prekey_api.dart';
import 'prekey_api_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('guffsuff/native_identity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AuthSession session;
  late AndroidDirectCrypto crypto;
  var calls = 0;
  DirectCryptoRoute outgoing() => DirectCryptoRoute(
    conversationId: fixture.conversation,
    senderUserId: fixture.user,
    senderDeviceId: fixture.device,
    recipientUserId: fixture.peer,
    recipientDeviceId: fixture.target,
    createdAtMillis: fixture.now.millisecondsSinceEpoch,
    expiresAtMillis:
        fixture.now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
  );
  Map<Object?, Object?> batch() => {
    'messageId': fixture.retry,
    'protocolVersion': 2,
    'deviceEnvelopes': [
      <Object?, Object?>{
        'recipientDeviceId': fixture.target,
        'opaquePayloadBase64': base64Encode(List.filled(13, 1)),
      },
    ],
  };
  Future<Map<String, List<int>>> send({String text = 'नमस्ते 👋'}) =>
      crypto.send(
        messageId: fixture.retry,
        routes: [outgoing()],
        text: text,
        claimedBundles: [],
      );
  DirectEnvelope incoming() => DirectEnvelope(
    fixture.retry,
    fixture.conversation,
    fixture.peer,
    fixture.target,
    fixture.user,
    fixture.device,
    fixture.now,
    fixture.now.add(const Duration(hours: 1)),
    List.filled(13, 2),
  );
  setUp(() async {
    calls = 0;
    session = await fixture.signIn(
      (_) async => throw StateError('Unexpected HTTP'),
    );
    crypto = AndroidDirectCrypto(session, clock: () => fixture.now);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    session.dispose();
  });

  test(
    'codec public publication validates matching identity and immutable bundle',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'initializePreKeys');
        expect(call.arguments, {
          'accountId': fixture.user,
          'deviceId': fixture.device,
        });
        final bundle = fixture.bundle();
        return <Object?, Object?>{
          'providerId': 'signalapp/libsignal',
          'providerVersion': '0.104.0',
          'supportsDirectMessaging': false,
          'identityPublicKeyBase64': bundle['identityPublicKeyBase64'],
          'registrationId': bundle['registrationId'],
          'bundle': bundle,
        };
      });
      final result = await crypto.initializePreKeys();
      expect(result.json, fixture.bundle());
      expect(
        () => result.json['privateKey'] = 'forbidden',
        throwsUnsupportedError,
      );
    },
  );

  test(
    'send crosses actual codec with public claims and returns immutable ciphertext',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'sendDirectMessage');
        expect(call.arguments['text'], 'नमस्ते 👋');
        expect(call.arguments['accountId'], fixture.user);
        expect(call.arguments['deviceId'], fixture.device);
        expect(call.arguments['routes'], [outgoing().json]);
        expect(call.arguments['claimedBundles'], [fixture.bundle(claim: true)]);
        return batch();
      });
      final result = await crypto.send(
        messageId: fixture.retry,
        routes: [outgoing()],
        text: 'नमस्ते 👋',
        claimedBundles: [
          PublicPrekeyBundle.parse(
            fixture.bundle(claim: true),
            now: fixture.now,
            expectedDeviceId: fixture.target,
          ),
        ],
      );
      expect(result[fixture.target], List.filled(13, 1));
      expect(() => result[fixture.target]![0] = 0, throwsUnsupportedError);
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );

  test(
    'malformed Unicode, oversized text, duplicate routes fail before native',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return batch();
      });
      for (final text in ['', ' ', String.fromCharCode(0xd800), 'क' * 3000]) {
        await expectLater(send(text: text), throwsFormatException);
      }
      await expectLater(
        crypto.send(
          messageId: fixture.retry,
          routes: [outgoing(), outgoing()],
          text: 'hello',
          claimedBundles: [],
        ),
        throwsFormatException,
      );
      expect(calls, 0);
    },
  );

  test(
    'wrong native target, metadata, private fields and malformed encodings fail',
    () async {
      final bad = <dynamic>[
        {...batch(), 'messageId': fixture.device},
        {...batch(), 'protocolVersion': 2.0},
        {...batch(), 'privateState': 'forbidden'},
        {...batch(), 'deviceEnvelopes': []},
        {
          ...batch(),
          'deviceEnvelopes': [
            {
              'recipientDeviceId': fixture.device,
              'opaquePayloadBase64': base64Encode(List.filled(13, 1)),
            },
          ],
        },
        {
          ...batch(),
          'deviceEnvelopes': [
            {
              'recipientDeviceId': fixture.target,
              'opaquePayloadBase64': 'AQID\n',
            },
          ],
        },
        {1: 'non-string key'},
      ];
      for (final response in bad) {
        messenger.setMockMethodCallHandler(channel, (_) async => response);
        await expectLater(send(), throwsFormatException);
      }
    },
  );

  test(
    'receive maps exact epoch route and returns only verified message',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'receiveDirectMessage');
        expect(
          call.arguments['route'],
          DirectCryptoRoute.fromEnvelope(incoming()).json,
        );
        expect(
          call.arguments['opaquePayloadBase64'],
          base64Encode(List.filled(13, 2)),
        );
        return {
          'messageId': fixture.conversation,
          'route': call.arguments['route'],
          'text': 'नमस्ते',
        };
      });
      final result = await crypto.receive(incoming());
      // Client message ID and server envelope ID belong to different namespaces.
      expect(result.messageId, fixture.conversation);
      expect(result.text, 'नमस्ते');
    },
  );

  test(
    'receive rejects tampered verified routing and invalid plaintext',
    () async {
      final route = DirectCryptoRoute.fromEnvelope(incoming()).json;
      for (final response in [
        {
          'messageId': fixture.retry,
          'route': {...route, 'conversationId': fixture.peer},
          'text': 'hello',
        },
        {'messageId': fixture.retry, 'route': route, 'text': ' '},
        {
          'messageId': fixture.retry,
          'route': {...route, 'createdAtMillis': 1.0},
          'text': 'hello',
        },
      ]) {
        messenger.setMockMethodCallHandler(channel, (_) async => response);
        await expectLater(crypto.receive(incoming()), throwsFormatException);
      }
    },
  );

  test('logout during native transaction suppresses stale results', () async {
    final started = Completer<void>();
    final response = Completer<dynamic>();
    messenger.setMockMethodCallHandler(channel, (_) async {
      started.complete();
      return response.future;
    });
    final pending = send();
    final assertion = expectLater(pending, throwsA(isA<AuthFailure>()));
    await started.future;
    await session.logout();
    response.complete(batch());
    await assertion;
  });

  test('plugin and native errors never expose diagnostics', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'SECRET', message: 'private keystore path');
    });
    await expectLater(
      send(),
      throwsA(
        isA<CryptoBridgeFailure>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('keystore')),
        ),
      ),
    );
    messenger.setMockMethodCallHandler(channel, null);
    await expectLater(send(), throwsA(isA<CryptoBridgeFailure>()));
  });
}
