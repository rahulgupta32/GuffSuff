import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:guffsuff_mobile/crypto/android_direct_crypto.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/direct_message_recovery.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'package:guffsuff_mobile/services/prekey_api.dart';
import 'prekey_api_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('guffsuff/native_identity');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AuthSession session;
  late AndroidDirectCrypto crypto;
  late DateTime clock;
  final wire = base64Encode(List.filled(13, 1));
  DirectCryptoRoute route({bool expired = false}) => DirectCryptoRoute(
    conversationId: fixture.conversation, senderUserId: fixture.user,
    senderDeviceId: fixture.device, recipientUserId: fixture.peer,
    recipientDeviceId: fixture.target,
    createdAtMillis: fixture.now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
    expiresAtMillis: fixture.now.add(Duration(hours: expired ? -1 : 1)).millisecondsSinceEpoch,
  );
  Map<String, dynamic> draft({bool expired = false, bool needsClaim = true}) => {
    'messageId': fixture.retry, 'routes': [route(expired: expired).json],
    'text': 'गफसफ तयार सन्देश', 'claimIds': {fixture.target: fixture.peer},
    'requiredClaimDeviceIds': needsClaim ? [fixture.target] : <String>[],
  };
  Map<String, dynamic> batch() => {
    'messageId': fixture.retry, 'protocolVersion': 2,
    'deviceEnvelopes': [
      {'recipientDeviceId': fixture.target, 'opaquePayloadBase64': wire},
    ],
  };
  Map<String, dynamic> saved() => {
    'messageId': fixture.retry, 'route': route().json,
    'batchFingerprintBase64': base64Encode(List.filled(32, 2)),
    'deviceEnvelopes': batch()['deviceEnvelopes'],
  };
  Map<String, dynamic> acknowledgement() => {
    'messageId': fixture.retry, 'serverEnvelopeId': fixture.retry,
    'isAccepted': true,
  };
  Future<void> signIn(Future<http.Response> Function(http.Request) handler) async {
    session = await fixture.signIn(handler);
    crypto = AndroidDirectCrypto(session, clock: () => clock);
  }
  DirectMessageRecoveryCoordinator coordinator() => DirectMessageRecoveryCoordinator(
    crypto, EnvelopeApi(session), prekeys: PrekeyApi(session, clock: () => clock),
    clock: () => clock,
  );
  Future<PreparedDirectIntent> prepare() => crypto.prepare(
    messageId: fixture.retry, routes: [route()], text: draft()['text'] as String,
  );
  setUp(() async {
    clock = fixture.now;
    await signIn((_) async => throw StateError('Unexpected HTTP'));
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    session.dispose();
  });

  test('prepared intents and completed ciphertext are immutable and exact', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'prepareDirectMessage') {
        expect(call.arguments['accountId'], fixture.user);
        expect(call.arguments['deviceId'], fixture.device);
        expect(call.arguments['routes'], draft()['routes']);
        return draft();
      }
      expect(call.method, 'completePreparedMessage');
      expect((call.arguments as Map).keys.toSet(), {
        'accountId', 'deviceId', 'messageId', 'claimedBundles',
      });
      expect(call.arguments['claimedBundles'], [fixture.bundle(claim: true)]);
      return batch();
    });
    final intent = await prepare();
    expect(intent.claimIds[fixture.target], fixture.peer);
    expect(() => intent.routes.clear(), throwsUnsupportedError);
    expect(() => intent.claimIds.clear(), throwsUnsupportedError);
    expect(() => intent.requiredClaimDeviceIds.clear(), throwsUnsupportedError);
    final completed = await crypto.complete(intent, [PublicPrekeyBundle.parse(
      fixture.bundle(claim: true), now: clock, expectedDeviceId: fixture.target,
    )]);
    expect(completed[fixture.target], List.filled(13, 1));
    expect(() => completed.clear(), throwsUnsupportedError);
    expect(() => completed[fixture.target]![0] = 9, throwsUnsupportedError);
  });

  test('restored draft parser rejects malformed private duplicate and wrong-scope data', () async {
    final invalid = <dynamic>[
      [draft(), draft()],
      [{...draft(), 'privateKey': 'forbidden'}],
      [{...draft(), 'claimIds': {fixture.device: fixture.peer}}],
      [{...draft(), 'claimIds': {fixture.target: 'invalid'}}],
      [{...draft(), 'requiredClaimDeviceIds': [fixture.target, fixture.target]}],
      [{...draft(), 'requiredClaimDeviceIds': [fixture.device]}],
      [{...draft(), 'text': '\uD800'}],
      [{...draft(), 'text': 'न'.padRight(8193, 'न')}],
      [{...draft(), 'routes': [route().json, route().json]}],
      [{...draft(), 'routes': [{...route().json, 'senderUserId': fixture.peer}]}],
      [{...draft(), 'routes': [{...route().json, 'conversationId': fixture.peer}]}],
      List.filled(65, draft()),
    ];
    for (final rows in invalid) {
      messenger.setMockMethodCallHandler(channel, (_) async => {'prepared': rows});
      await expectLater(crypto.prepared(fixture.conversation), throwsFormatException);
    }
  });

  test('preparation rejects changed response intent and invalid input before dispatch', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return {...draft(), 'text': 'changed'};
    });
    await expectLater(prepare(), throwsFormatException);
    expect(calls, 1);
    await expectLater(crypto.prepare(messageId: fixture.retry,
        routes: [route(), route()], text: 'duplicate'), throwsFormatException);
    await expectLater(crypto.prepare(messageId: fixture.retry,
        routes: [route(expired: true)], text: 'expired'), throwsFormatException);
    expect(calls, 1);
  });

  test('completion rejects wrong claim target and changed ciphertext inventory', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => draft());
    final intent = await prepare();
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return {...batch(), 'messageId': fixture.peer};
    });
    final claim = PublicPrekeyBundle.parse({...fixture.bundle(claim: true),
      'deviceId': fixture.conversation}, now: clock, expectedDeviceId: fixture.conversation);
    await expectLater(crypto.complete(intent, [claim]), throwsFormatException);
    expect(calls, 0);
    await expectLater(crypto.complete(intent, []), throwsFormatException);
    expect(calls, 1);
  });

  test('discovery persists intent before any claim and exposes no early send', () async {
    session.dispose();
    final events = <String>[];
    await signIn((request) async {
      events.add('discover');
      expect(request.method, 'GET');
      expect(request.url.path,
          '/api/v1/conversations/${fixture.conversation}/recipients/${fixture.peer}/devices');
      return http.Response(jsonEncode([{'id': fixture.target}]), 200);
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add('prepare');
      expect(call.method, 'prepareDirectMessage');
      return draft();
    });
    final intent = await coordinator().prepareNew(messageId: fixture.retry,
      conversationId: fixture.conversation, recipientUserId: fixture.peer,
      text: draft()['text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(route().createdAtMillis, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(route().expiresAtMillis, isUtc: true));
    expect(intent.claimIds[fixture.target], fixture.peer);
    expect(events, ['discover', 'prepare']);
  });

  test('lost claim response reuses original UUID after coordinator restart without discovery', () async {
    session.dispose();
    final bodies = <String>[];
    final events = <String>[];
    await signIn((request) async {
      if (request.url.path.endsWith('/prekey-claims')) {
        events.add('claim');
        bodies.add(request.body);
        expect(request.method, 'POST');
        if (bodies.length == 1) throw StateError('Lost claim response');
        return http.Response(jsonEncode(fixture.bundle(claim: true)), 200);
      }
      events.add('submit');
      expect(request.url.path.endsWith('/device-envelopes'), isTrue);
      expect(jsonDecode(request.body)['deviceEnvelopes'], batch()['deviceEnvelopes']);
      expect(jsonDecode(request.body)['idempotencyKey'], fixture.retry);
      return http.Response(jsonEncode({...fixture.accepted(), 'payload_byte_length': 13}), 200);
    });
    var encrypted = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'preparedDirectMessages':
          events.add('restore');
          return {'prepared': encrypted ? [] : [draft()]};
        case 'completePreparedMessage':
          events.add('encrypt');
          expect(call.arguments['claimedBundles'], [fixture.bundle(claim: true)]);
          encrypted = true;
          return batch();
        case 'pendingDirectMessages':
          events.add('pending');
          return {'pending': [saved()]};
        case 'markDirectMessageAccepted':
          events.add('accepted');
          return acknowledgement();
        default:
          throw StateError('Unexpected native operation');
      }
    });
    await expectLater(coordinator().resumePrepared(fixture.conversation), throwsStateError);
    expect(encrypted, isFalse);
    expect(await coordinator().resumePrepared(fixture.conversation), 1);
    expect(bodies, [jsonEncode({'claimId': fixture.peer}), jsonEncode({'claimId': fixture.peer})]);
    expect(events, ['restore', 'claim', 'restore', 'claim', 'encrypt', 'pending', 'submit', 'accepted']);
  });

  test('lost native completion response resumes committed bytes without claims or re-encryption', () async {
    session.dispose();
    var claims = 0;
    var encryptions = 0;
    var encrypted = false;
    await signIn((request) async {
      if (request.url.path.endsWith('/prekey-claims')) {
        claims++;
        return http.Response(jsonEncode(fixture.bundle(claim: true)), 200);
      }
      expect(jsonDecode(request.body)['deviceEnvelopes'], batch()['deviceEnvelopes']);
      return http.Response(jsonEncode({...fixture.accepted(), 'payload_byte_length': 13}), 200);
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'preparedDirectMessages':
          return {'prepared': encrypted ? [] : [draft()]};
        case 'completePreparedMessage':
          encrypted = true;
          encryptions++;
          throw PlatformException(code: 'lost_response');
        case 'pendingDirectMessages':
          return {'pending': [saved()]};
        case 'markDirectMessageAccepted':
          return acknowledgement();
        default:
          throw StateError('Unexpected native operation');
      }
    });
    await expectLater(coordinator().resumePrepared(fixture.conversation), throwsA(isA<CryptoBridgeFailure>()));
    expect(await coordinator().resumePrepared(fixture.conversation), 1);
    expect(claims, 1);
    expect(encryptions, 1);
  });

  test('established session drafts encrypt with no additional prekey claims', () async {
    final events = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add(call.method);
      if (call.method == 'preparedDirectMessages') {
        return {'prepared': [draft(needsClaim: false)]};
      }
      if (call.method == 'completePreparedMessage') {
        expect(call.arguments['claimedBundles'], isEmpty);
        return batch();
      }
      return {'pending': []};
    });
    expect(await coordinator().resumePrepared(fixture.conversation), 0);
    expect(events, ['preparedDirectMessages', 'completePreparedMessage', 'pendingDirectMessages']);
  });

  test('expired drafts remain stored and never claim or encrypt', () async {
    final events = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add(call.method);
      if (call.method == 'preparedDirectMessages') {
        return {'prepared': [draft(expired: true)]};
      }
      return {'pending': []};
    });
    expect(await coordinator().resumePrepared(fixture.conversation), 0);
    expect(events, ['preparedDirectMessages', 'pendingDirectMessages']);
  });

  test('logout while a claim is pending prevents native encryption and concurrent runs', () async {
    session.dispose();
    final started = Completer<void>();
    final response = Completer<http.Response>();
    await signIn((request) async {
      started.complete();
      return response.future;
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'preparedDirectMessages');
      return {'prepared': [draft()]};
    });
    final recovery = coordinator();
    final running = recovery.resumePrepared(fixture.conversation);
    final assertion = expectLater(running, throwsA(isA<AuthFailure>()));
    await started.future;
    await expectLater(recovery.retryPending(fixture.conversation), throwsStateError);
    await session.logout();
    response.complete(http.Response(jsonEncode(fixture.bundle(claim: true)), 200));
    await assertion;
  });

  test('expiry during claims stops native completion and HTTP submission', () async {
    session.dispose();
    await signIn((request) async {
      expect(request.url.path.endsWith('/prekey-claims'), isTrue);
      clock = clock.add(const Duration(hours: 2));
      return http.Response(jsonEncode(fixture.bundle(claim: true)), 200);
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'preparedDirectMessages');
      return {'prepared': [draft()]};
    });
    await expectLater(coordinator().resumePrepared(fixture.conversation), throwsFormatException);
  });

  test('preparation requires one shared session and configured prekey transport', () async {
    final other = await fixture.signIn((_) async => throw StateError('Unexpected HTTP'));
    try {
      expect(() => DirectMessageRecoveryCoordinator(crypto, EnvelopeApi(session),
          prekeys: PrekeyApi(other)), throwsArgumentError);
      await expectLater(DirectMessageRecoveryCoordinator(crypto, EnvelopeApi(session))
          .resumePrepared(fixture.conversation), throwsStateError);
    } finally {
      other.dispose();
    }
  });
}
