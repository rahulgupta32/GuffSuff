import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'auth_session_test.dart' show MemoryStorage, tokens;

const id = '018f3a2b-1234-7000-8000-000000000001';
Future<AuthSession> signedIn(http.Client client) async {
  final storage = MemoryStorage()..saved = tokens();
  final session = AuthSession(
    storage: storage,
    client: client,
    baseUrl: 'https://api.example.test',
  );
  await session.restore();
  return session;
}

http.Response refreshed() => http.Response(jsonEncode(tokens()), 200);
void main() {
  test(
    'submits opaque bytes with authenticated JSON and stable caller retry key',
    () async {
      final session = await signedIn(
        MockClient((request) async {
          if (request.url.path.endsWith('/refresh')) return refreshed();
          expect(request.url.path, '/api/v1/conversations/$id/envelopes');
          expect(request.headers['Authorization'], 'Bearer access');
          expect(request.headers['Content-Type'], 'application/json');
          final body = jsonDecode(request.body);
          expect(body['idempotencyKey'], 'persisted-key');
          expect(body['opaquePayloadBase64'], 'AQID');
          expect(body.containsKey('plaintext'), false);
          return http.Response(jsonEncode({'id': id}), 201);
        }),
      );
      final result = await EnvelopeApi(session).submit(
        conversationId: id,
        recipientUserId: id,
        idempotencyKey: 'persisted-key',
        ciphertext: [1, 2, 3],
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2027),
      );
      expect(result['id'], id);
    },
  );
  test(
    'POST retries after refresh preserve the same payload and retry key',
    () async {
      var refreshes = 0;
      final bodies = <String>[];
      final session = await signedIn(
        MockClient((request) async {
          if (request.url.path.endsWith('/refresh')) {
            refreshes++;
            return refreshed();
          }
          bodies.add(request.body);
          return bodies.length == 1
              ? http.Response('{}', 401)
              : http.Response('{"id":"$id"}', 201);
        }),
      );
      await EnvelopeApi(session).submit(
        conversationId: id,
        recipientUserId: id,
        idempotencyKey: 'stable',
        ciphertext: [7],
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2027),
      );
      expect(refreshes, 2);
      expect(bodies.length, 2);
      expect(bodies.first, bodies.last);
    },
  );
  test(
    'pending fetch is scoped and never acknowledges automatically',
    () async {
      final requests = <String>[];
      final session = await signedIn(
        MockClient((request) async {
          if (request.url.path.endsWith('/refresh')) return refreshed();
          requests.add(request.url.path);
          return http.Response('[{"id":"$id"}]', 200);
        }),
      );
      expect((await EnvelopeApi(session).pending(id)).single['id'], id);
      expect(requests, ['/api/v1/conversations/$id/envelopes/pending']);
    },
  );
  test('read receipt URL and body use the same envelope', () async {
    final session = await signedIn(
      MockClient((request) async {
        if (request.url.path.endsWith('/refresh')) return refreshed();
        expect(request.url.path, '/api/v1/envelopes/$id/read');
        expect(jsonDecode(request.body), {'lastReadEnvelopeId': id});
        return http.Response('{}', 200);
      }),
    );
    await EnvelopeApi(session).read(id);
  });
  test(
    'invalid ciphertext and path identifiers fail before network requests',
    () async {
      var requests = 0;
      final session = await signedIn(
        MockClient((request) async {
          if (request.url.path.endsWith('/refresh')) return refreshed();
          requests++;
          return http.Response('{}', 200);
        }),
      );
      final api = EnvelopeApi(session);
      await expectLater(api.pending('../auth'), throwsArgumentError);
      for (final bytes in [
        <int>[],
        [-1],
        [256],
        List.filled(65537, 1),
      ]) {
        await expectLater(
          api.submit(
            conversationId: id,
            recipientUserId: id,
            idempotencyKey: 'key',
            ciphertext: bytes,
            createdAt: DateTime.utc(2026),
            expiresAt: DateTime.utc(2027),
          ),
          throwsArgumentError,
        );
      }
      expect(requests, 0);
    },
  );
  test(
    'malformed server response fails instead of manufacturing success',
    () async {
      final session = await signedIn(
        MockClient(
          (request) async =>
              request.url.path.endsWith('/refresh')
                  ? refreshed()
                  : http.Response('{}', 200),
        ),
      );
      await expectLater(
        EnvelopeApi(session).pending(id),
        throwsFormatException,
      );
    },
  );
  test(
    'a response arriving after logout cannot return data to the old session',
    () async {
      late AuthSession session;
      session = await signedIn(
        MockClient((request) async {
          if (request.url.path.endsWith('/refresh')) return refreshed();
          if (request.url.path.endsWith('/logout')) {
            return http.Response('{}', 200);
          }
          await session.logout();
          return http.Response('[{"id":"$id"}]', 200);
        }),
      );
      await expectLater(
        EnvelopeApi(session).pending(id),
        throwsA(isA<AuthFailure>()),
      );
      expect(session.isAuthenticated, false);
    },
  );
}
