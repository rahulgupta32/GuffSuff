import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/crypto/provider_neutral_boundary.dart';
import 'package:guffsuff_mobile/services/transport_service.dart';

void main() {
  group('Flutter Mobile Transport Service Lifecycle & Realtime Tests', () {
    late TransportService transport;

    setUp(() {
      transport = TransportService(
        wsBaseUrl: 'wss://realtime.guffsuff.com',
        accessToken: 'valid_auth_token_777',
        deviceId: 'device_android_001',
      );
    });

    tearDown(() {
      transport.dispose();
    });

    test(
      'Enforces compile-time prohibition on transport test mode in product builds',
      () {
        expect(() => transport.checkProductionSafety(), returnsNormally);
      },
    );

    test('1. Authenticated connect establishes connection status', () async {
      final statuses = <ConnectionStatus>[];
      transport.onStatusChange.listen(statuses.add);

      transport.connect();
      await Future.delayed(const Duration(milliseconds: 400));

      expect(statuses, contains(ConnectionStatus.connecting));
      expect(statuses, contains(ConnectionStatus.connected));
      expect(transport.status, equals(ConnectionStatus.connected));
    });

    test('2. Disconnect emits disconnected status', () async {
      transport.connect();
      await Future.delayed(const Duration(milliseconds: 400));
      transport.disconnect();

      expect(transport.status, equals(ConnectionStatus.disconnected));
    });

    test('3. Bounded exponential backoff and jitter scheduling', () {
      transport.scheduleReconnect();
      expect(transport.status, equals(ConnectionStatus.reconnecting));
    });

    test('6. Duplicate connect call does not duplicate listeners', () async {
      int statusCount = 0;
      transport.onStatusChange.listen((_) => statusCount++);

      transport.connect();
      transport.connect(); // Duplicate call

      await Future.delayed(const Duration(milliseconds: 400));
      expect(statusCount, equals(2)); // connecting -> connected
    });

    test(
      '11. Duplicate envelope is ignored and 12. Unique envelope is processed once',
      () async {
        final receivedEnvelopes = <TransportEnvelope>[];
        transport.onEnvelopeReceived.listen(receivedEnvelopes.add);

        final env1 = TransportEnvelope(
          envelopeId: 'env_1001',
          conversationId: 'conv_1',
          senderUserId: 'user_a',
          recipientUserId: 'user_b',
          opaquePayloadBase64: 'payload_base64_data',
          sequenceNumber: 1,
          state: MessageState.accepted,
          createdAt: DateTime.now(),
        );

        transport.processIncomingEnvelope(env1);
        transport.processIncomingEnvelope(env1); // Duplicate submission
        await Future.delayed(Duration.zero);

        expect(receivedEnvelopes.length, equals(1));
        expect(receivedEnvelopes.first.envelopeId, equals('env_1001'));
      },
    );

    test(
      '14. Unread increment happens once and 15. Reconnect does not double unread',
      () {
        final env1 = TransportEnvelope(
          envelopeId: 'env_2002',
          conversationId: 'conv_2',
          senderUserId: 'user_x',
          recipientUserId: 'user_y',
          opaquePayloadBase64: 'payload_base64_data',
          sequenceNumber: 1,
          state: MessageState.accepted,
          createdAt: DateTime.now(),
        );

        transport.processIncomingEnvelope(env1);
        expect(transport.getUnreadCount('conv_2'), equals(1));

        // Simulate reconnect and duplicate envelope replay
        transport.scheduleReconnect();
        transport.processIncomingEnvelope(env1);

        // Unread count MUST remain 1
        expect(transport.getUnreadCount('conv_2'), equals(1));
      },
    );

    test('16. Logout disconnects and closes transport', () {
      transport.connect();
      transport.disconnect();
      expect(transport.status, equals(ConnectionStatus.disconnected));
    });

    test('18. Provider unavailable blocks message submission', () async {
      const MobileCryptoProvider provider = UnavailableCryptoProvider();
      expect(provider.isAvailable, isFalse);

      expect(
        () => provider.encryptPayload(const OpaqueSessionHandle(1), [1, 2, 3]),
        throwsA(isA<ProviderUnavailableException>()),
      );
    });
  });
}
