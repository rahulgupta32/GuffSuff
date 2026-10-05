import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/crypto/provider_neutral_boundary.dart';

void main() {
  group('Provider-Neutral Mobile Boundary Contract & Safety Tests', () {
    test('UnavailableCryptoProvider fails closed on all operations', () async {
      const provider = UnavailableCryptoProvider();

      expect(
        () => provider.queryCapabilities(),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.initializeDeviceIdentity(),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.establishOutboundSession('bundle_001'),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.createGroupState('grp_001', ['dev_1']),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.encryptPayload(const OpaqueSessionHandle(1), [1, 2, 3]),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.decryptPayload(const OpaqueSessionHandle(1), [1, 2, 3]),
        throwsA(isA<ProviderUnavailableException>()),
      );
      expect(
        () => provider.disposeHandle(const OpaqueSessionHandle(1)),
        throwsA(isA<ProviderUnavailableException>()),
      );
    });

    test(
      'assertProductionProviderSafety hard-rejects test provider in production mode',
      () {
        final testProvider = TestBoundaryCryptoProvider();
        final caps = testProvider.queryCapabilities();

        expect(caps.isTestProvider, isTrue);

        // In non-production mode, safety assertion passes
        expect(
          () => assertProductionProviderSafety(caps, false),
          returnsNormally,
        );

        // In production mode, safety assertion throws ProductionSafetyException
        expect(
          () => assertProductionProviderSafety(caps, true),
          throwsA(isA<ProductionSafetyException>()),
        );
      },
    );

    test(
      'TestBoundaryCryptoProvider manages opaque handle lifecycles',
      () async {
        final provider = TestBoundaryCryptoProvider();

        final identity = await provider.initializeDeviceIdentity();
        expect(identity.handleId, greaterThan(0));

        final session = await provider.establishOutboundSession('prekey_101');
        expect(session.handleId, greaterThan(identity.handleId));

        final payload = [71, 117, 102, 102, 83, 117, 102, 102]; // "GuffSuff"
        final encrypted = await provider.encryptPayload(session, payload);
        final decrypted = await provider.decryptPayload(session, encrypted);

        expect(decrypted, equals(payload));

        // Dispose session handle
        await provider.disposeHandle(session);

        // Attempting reuse after dispose throws
        expect(
          () => provider.encryptPayload(session, payload),
          throwsA(isA<ProviderUnavailableException>()),
        );

        // Double-free throws
        expect(
          () => provider.disposeHandle(session),
          throwsA(isA<ProviderUnavailableException>()),
        );
      },
    );
  });
}
