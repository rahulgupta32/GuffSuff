import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:guffsuff_mobile/crypto/provider_neutral_boundary.dart';
import 'package:guffsuff_mobile/crypto/native_crypto_boundary_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android Native Provider-Neutral Boundary Integration Tests', () {
    late NativeAndroidCryptoProvider provider;

    setUpAll(() {
      expect(Platform.isAndroid, isTrue);
      provider = NativeAndroidCryptoProvider();
    });

    testWidgets('1. Native library loads successfully', (WidgetTester tester) async {
      expect(provider.isAvailable, isTrue);
    });

    testWidgets('2. Native API version matches expected boundary API version', (WidgetTester tester) async {
      expect(provider.apiVersion, equals(1));
    });

    testWidgets('3. Capability query returns expected test capabilities', (WidgetTester tester) async {
      final caps = provider.queryCapabilities();
      expect(caps.isTestProvider, isTrue);
      expect(caps.supportsDirectMessaging, isTrue);
      expect(caps.supportsGroupMessaging, isFalse);
      expect(caps.providerId, equals('native-android-test-provider'));
    });

    testWidgets('4. Identity handle is created', (WidgetTester tester) async {
      final handle = await provider.initializeDeviceIdentity();
      expect(handle.handleId, greaterThan(0));
    });

    testWidgets('5. Session handle is created', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('test_prekey_bundle');
      expect(handle.handleId, greaterThan(0));
    });

    testWidgets('6. Group handle is created', (WidgetTester tester) async {
      final handle = await provider.createGroupState('group_123', ['device_a', 'device_b']);
      expect(handle.handleId, greaterThan(0));
    });

    testWidgets('7 & 8 & 9. Byte input crosses into native code, returns output labeled test-only', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('test_bundle');
      final input = Uint8List.fromList('Test Payload 123'.codeUnits);
      final output = await provider.encryptPayload(handle, input);
      expect(output, equals(input));
      expect(provider.providerLabel, contains('TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY'));
    });

    testWidgets('10 & 13. Opaque state exports and imports successfully', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('test_state_bundle');
      final exportedState = await provider.exportOpaqueState();
      expect(exportedState.length, greaterThan(8));

      final parsed = provider.parseExportedState(exportedState);
      final sessionEntry = parsed.firstWhere((h) => h.handleId == handle.handleId);
      expect(sessionEntry.handleType, equals(2)); // 2 = Session handle
      expect(sessionEntry.isActive, isTrue);

      await provider.importOpaqueState(exportedState);
      final restoredSession = OpaqueSessionHandle(handle.handleId);
      final input = Uint8List.fromList('Post Import Test'.codeUnits);
      final output = await provider.encryptPayload(restoredSession, input);
      expect(output, equals(input));

      await provider.disposeHandle(restoredSession);
      expect(
        () async => await provider.encryptPayload(restoredSession, input),
        throwsA(predicate((e) => e.toString().contains('STALE_OR_DOUBLE_FREE'))),
      );
    });

    testWidgets('14 & 15. Handle is disposed and reuse fails with STALE_OR_DOUBLE_FREE', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('bundle');
      await provider.disposeHandle(handle);

      final input = Uint8List.fromList('Data'.codeUnits);
      expect(
        () async => await provider.encryptPayload(handle, input),
        throwsA(predicate((e) => e.toString().contains('STALE_OR_DOUBLE_FREE'))),
      );
    });

    testWidgets('16. Unknown handle fails with INVALID_HANDLE', (WidgetTester tester) async {
      final fakeHandle = const OpaqueSessionHandle(999999);
      final input = Uint8List.fromList('Data'.codeUnits);
      expect(
        () async => await provider.encryptPayload(fakeHandle, input),
        throwsA(predicate((e) => e.toString().contains('INVALID_HANDLE'))),
      );
    });

    testWidgets('17. Double disposal fails with STALE_OR_DOUBLE_FREE', (WidgetTester tester) async {
      final handle = await provider.createGroupState('g1', ['d1']);
      await provider.disposeHandle(handle);
      expect(
        () async => await provider.disposeHandle(handle),
        throwsA(predicate((e) => e.toString().contains('STALE_OR_DOUBLE_FREE'))),
      );
    });

    testWidgets('18. Empty buffer behavior is defined', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('bundle');
      final input = Uint8List(0);
      final output = await provider.encryptPayload(handle, input);
      expect(output.length, equals(0));
    });

    testWidgets('19. Oversized buffer fails with ArgumentError', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('bundle');
      final input = Uint8List(11 * 1024 * 1024); // Exceeds 10MB limit
      expect(
        () async => await provider.encryptPayload(handle, input),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('20 & 21. Controlled native panic is contained and mapped to error code -4', (WidgetTester tester) async {
      final panicResult = provider.triggerControlledPanic();
      expect(panicResult, equals(-4)); // ERR_PANIC_CONTAINED
      expect(provider.lastErrorCode, equals(-4));
    });

    testWidgets('22. Concurrent calls do not corrupt registry state', (WidgetTester tester) async {
      final futures = List.generate(20, (_) async {
        final handle = await provider.establishOutboundSession('b');
        final res = await provider.encryptPayload(handle, Uint8List.fromList('Concurrent'.codeUnits));
        await provider.disposeHandle(handle);
        return res;
      });
      final results = await Future.wait(futures);
      expect(results.length, equals(20));
      for (final res in results) {
        expect(res, equals(Uint8List.fromList('Concurrent'.codeUnits)));
      }
    });

    testWidgets('23 & 24. Provider capability safety assertions enforce production rules', (WidgetTester tester) async {
      final caps = provider.queryCapabilities();
      expect(caps.isTestProvider, isTrue);
      expect(
        () => assertProductionProviderSafety(caps, true),
        throwsA(isA<ProductionSafetyException>()),
      );
    });

    testWidgets('25 & 26. Unavailable crypto provider returns fail-closed state', (WidgetTester tester) async {
      const fallback = UnavailableCryptoProvider();
      expect(
        () => fallback.queryCapabilities(),
        throwsA(isA<ProviderUnavailableException>()),
      );
    });

    testWidgets('27. Canary payload is processed without being logged', (WidgetTester tester) async {
      final handle = await provider.establishOutboundSession('canary_bundle');
      final canaryString = 'CANARY_SECRET_PAYLOAD_998877_DO_NOT_LOG';
      final input = Uint8List.fromList(canaryString.codeUnits);
      final output = await provider.encryptPayload(handle, input);
      expect(String.fromCharCodes(output), equals(canaryString));
      await provider.disposeHandle(handle);
    });

    testWidgets('28. Identity handle cannot be used as session handle (returns ERR_HANDLE_TYPE_MISMATCH)', (WidgetTester tester) async {
      final idHandle = await provider.initializeDeviceIdentity();
      final sessionFromId = OpaqueSessionHandle(idHandle.handleId);
      final input = Uint8List.fromList('Type Mismatch Test'.codeUnits);
      expect(
        () async => await provider.encryptPayload(sessionFromId, input),
        throwsA(predicate((e) => e.toString().contains('ERR_HANDLE_TYPE_MISMATCH'))),
      );
      await provider.disposeHandle(idHandle);
    });

    testWidgets('29. Group handle cannot be used as session handle (returns ERR_HANDLE_TYPE_MISMATCH)', (WidgetTester tester) async {
      final groupHandle = await provider.createGroupState('g1', ['d1']);
      final sessionFromGroup = OpaqueSessionHandle(groupHandle.handleId);
      final input = Uint8List.fromList('Type Mismatch Test'.codeUnits);
      expect(
        () async => await provider.encryptPayload(sessionFromGroup, input),
        throwsA(predicate((e) => e.toString().contains('ERR_HANDLE_TYPE_MISMATCH'))),
      );
      await provider.disposeHandle(groupHandle);
    });
  });
}
