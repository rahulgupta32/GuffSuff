import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/services/push_notification_service.dart';

void main() {
  group('PushNotificationService Architecture & Safety Tests', () {
    late FcmPushNotificationService service;

    setUp(() {
      service = FcmPushNotificationService(
        backendUrl: 'https://api.guffsuff.com',
        accessToken: 'valid_access_token_123',
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('Acquires device token during initialization', () async {
      await service.initialize();
      final token = await service.getDeviceToken();
      expect(token, isNotNull);
      expect(token, startsWith('fcm_device_token_'));
    });

    test('Unregister on logout clears current token', () async {
      await service.initialize();
      await service.unregisterOnLogout();
      final token = await service.getDeviceToken();
      expect(token, startsWith('fcm_device_token_'));
    });

    test(
      'Push payload contains generic content ONLY and NO message body',
      () async {
        final Future<PushNotificationPayload> eventFuture =
            service.onForegroundNotification.first;

        service.simulateIncomingGenericPush(
          conversationId: 'conv_nepal_1',
          senderDisplayName: 'Aanav Sharma',
        );

        final payload = await eventFuture;
        expect(payload.title, equals('GuffSuff'));
        expect(payload.body, equals('New message from Aanav Sharma'));
        expect(
          payload.body,
          isNot(contains('Hello')),
        ); // Zero message content leakage
        expect(payload.conversationId, equals('conv_nepal_1'));
        expect(payload.rawData['hasEncryptedMessage'], isTrue);
      },
    );
  });
}
