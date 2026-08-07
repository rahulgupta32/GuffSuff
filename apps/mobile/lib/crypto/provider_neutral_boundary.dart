/// Provider-Neutral Mobile Cryptographic Boundary
///
/// SECURITY NOTICE:
/// This interface layer defines opaque handles, error models, and capability
/// queries ONLY. It contains zero embedded production cryptographic backends.
library;

class OpaqueIdentityHandle {
  final int handleId;
  const OpaqueIdentityHandle(this.handleId);
}

class OpaqueSessionHandle {
  final int handleId;
  const OpaqueSessionHandle(this.handleId);
}

class OpaqueGroupHandle {
  final int handleId;
  const OpaqueGroupHandle(this.handleId);
}

class ProviderCapabilityMap {
  final bool supportsDirectMessaging;
  final bool supportsGroupMessaging;
  final List<int> supportedProtocolVersions;
  final String providerId;
  final String providerVersion;
  final bool isTestProvider;

  const ProviderCapabilityMap({
    required this.supportsDirectMessaging,
    required this.supportsGroupMessaging,
    required this.supportedProtocolVersions,
    required this.providerId,
    required this.providerVersion,
    required this.isTestProvider,
  });
}

class ProviderUnavailableException implements Exception {
  final String message;
  const ProviderUnavailableException([
    this.message = 'SECURE MESSAGING PROVIDER UNAVAILABLE',
  ]);

  @override
  String toString() => 'ProviderUnavailableException: $message';
}

class ProductionSafetyException implements Exception {
  final String message;
  const ProductionSafetyException(this.message);

  @override
  String toString() => 'ProductionSafetyException: $message';
}

void assertProductionProviderSafety(
  ProviderCapabilityMap capabilities,
  bool isProductionEnvironment,
) {
  if (isProductionEnvironment && capabilities.isTestProvider) {
    throw ProductionSafetyException(
      'PROHIBITED: Test provider "${capabilities.providerId}" cannot be loaded in production environment',
    );
  }
}

abstract class MobileCryptoProvider {
  bool get isAvailable;
  ProviderCapabilityMap queryCapabilities();
  Future<OpaqueIdentityHandle> initializeDeviceIdentity();
  Future<OpaqueSessionHandle> establishOutboundSession(
    String recipientPrekeyBundle,
  );
  Future<OpaqueGroupHandle> createGroupState(
    String groupId,
    List<String> memberDeviceIds,
  );
  Future<List<int>> encryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> plaintext,
  );
  Future<List<int>> decryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> ciphertext,
  );
  Future<void> disposeHandle(dynamic handle);
}

/// Fallback provider returned when no production provider is registered.
class UnavailableCryptoProvider implements MobileCryptoProvider {
  const UnavailableCryptoProvider();

  @override
  bool get isAvailable => false;

  @override
  ProviderCapabilityMap queryCapabilities() {
    throw const ProviderUnavailableException();
  }

  @override
  Future<OpaqueIdentityHandle> initializeDeviceIdentity() async {
    throw const ProviderUnavailableException();
  }

  @override
  Future<OpaqueSessionHandle> establishOutboundSession(
    String recipientPrekeyBundle,
  ) async {
    throw const ProviderUnavailableException();
  }

  @override
  Future<OpaqueGroupHandle> createGroupState(
    String groupId,
    List<String> memberDeviceIds,
  ) async {
    throw const ProviderUnavailableException();
  }

  @override
  Future<List<int>> encryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> plaintext,
  ) async {
    throw const ProviderUnavailableException();
  }

  @override
  Future<List<int>> decryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> ciphertext,
  ) async {
    throw const ProviderUnavailableException();
  }

  @override
  Future<void> disposeHandle(dynamic handle) async {
    throw const ProviderUnavailableException();
  }
}

/// Test boundary provider used in development/testing only.
/// TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY
class TestBoundaryCryptoProvider implements MobileCryptoProvider {
  int _counter = 100;
  final Set<int> _activeHandles = {};

  @override
  bool get isAvailable => true;

  @override
  ProviderCapabilityMap queryCapabilities() {
    return const ProviderCapabilityMap(
      supportsDirectMessaging: true,
      supportsGroupMessaging: false,
      supportedProtocolVersions: [1],
      providerId: 'TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY',
      providerVersion: '0.1.0-test',
      isTestProvider: true,
    );
  }

  @override
  Future<OpaqueIdentityHandle> initializeDeviceIdentity() async {
    final id = ++_counter;
    _activeHandles.add(id);
    return OpaqueIdentityHandle(id);
  }

  @override
  Future<OpaqueSessionHandle> establishOutboundSession(
    String recipientPrekeyBundle,
  ) async {
    final id = ++_counter;
    _activeHandles.add(id);
    return OpaqueSessionHandle(id);
  }

  @override
  Future<OpaqueGroupHandle> createGroupState(
    String groupId,
    List<String> memberDeviceIds,
  ) async {
    final id = ++_counter;
    _activeHandles.add(id);
    return OpaqueGroupHandle(id);
  }

  @override
  Future<List<int>> encryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> plaintext,
  ) async {
    if (!_activeHandles.contains(sessionHandle.handleId)) {
      throw const ProviderUnavailableException('INVALID_HANDLE');
    }
    // Non-cryptographic test byte transfer only
    return List<int>.from(plaintext);
  }

  @override
  Future<List<int>> decryptPayload(
    OpaqueSessionHandle sessionHandle,
    List<int> ciphertext,
  ) async {
    if (!_activeHandles.contains(sessionHandle.handleId)) {
      throw const ProviderUnavailableException('INVALID_HANDLE');
    }
    return List<int>.from(ciphertext);
  }

  @override
  Future<void> disposeHandle(dynamic handle) async {
    int? handleId;
    if (handle is OpaqueIdentityHandle) handleId = handle.handleId;
    if (handle is OpaqueSessionHandle) handleId = handle.handleId;
    if (handle is OpaqueGroupHandle) handleId = handle.handleId;

    if (handleId != null) {
      if (!_activeHandles.contains(handleId)) {
        throw const ProviderUnavailableException('STALE_OR_DOUBLE_FREE_HANDLE');
      }
      _activeHandles.remove(handleId);
    }
  }
}
