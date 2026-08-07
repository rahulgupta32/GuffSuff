import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'provider_neutral_boundary.dart';

// FFI Struct for NativeCapabilityMap
final class NativeCapabilityMapStruct extends Struct {
  @Uint8()
  external int supportsDirectMessaging;

  @Uint8()
  external int supportsGroupMessaging;

  @Uint8()
  external int isTestProvider;

  @Uint32()
  external int apiVersion;
}

// Native FFI Function Types
typedef NativeApiVersionC = Uint32 Function();
typedef NativeApiVersionDart = int Function();

typedef QueryCapabilitiesC = Int32 Function(Pointer<NativeCapabilityMapStruct>);
typedef QueryCapabilitiesDart = int Function(Pointer<NativeCapabilityMapStruct>);

typedef CreateHandleC = Int32 Function(Pointer<Uint64>);
typedef CreateHandleDart = int Function(Pointer<Uint64>);

typedef TransformPayloadC = Int32 Function(
  Uint64 handle,
  Pointer<Uint8> inBuf,
  IntPtr inLen,
  Pointer<Uint8> outBuf,
  IntPtr outMaxLen,
  Pointer<IntPtr> outLen,
);
typedef TransformPayloadDart = int Function(
  int handle,
  Pointer<Uint8> inBuf,
  int inLen,
  Pointer<Uint8> outBuf,
  int outMaxLen,
  Pointer<IntPtr> outLen,
);

typedef DisposeHandleC = Int32 Function(Uint64);
typedef DisposeHandleDart = int Function(int);

typedef ExportStateC = Int32 Function(Pointer<Uint8>, IntPtr, Pointer<IntPtr>);
typedef ExportStateDart = int Function(Pointer<Uint8>, int, Pointer<IntPtr>);

typedef ImportStateC = Int32 Function(Pointer<Uint8>, IntPtr);
typedef ImportStateDart = int Function(Pointer<Uint8>, int);

typedef TriggerPanicC = Int32 Function();
typedef TriggerPanicDart = int Function();

typedef LastErrorCodeC = Int32 Function();
typedef LastErrorCodeDart = int Function();

class NativeAndroidCryptoProvider implements MobileCryptoProvider {
  late final DynamicLibrary _lib;
  late final NativeApiVersionDart _apiVersion;
  late final QueryCapabilitiesDart _queryCapabilities;
  late final CreateHandleDart _createIdentityHandle;
  late final CreateHandleDart _createSessionHandle;
  late final CreateHandleDart _createGroupHandle;
  late final TransformPayloadDart _transformPayload;
  late final DisposeHandleDart _disposeHandle;
  late final ExportStateDart _exportState;
  late final ImportStateDart _importState;
  late final TriggerPanicDart _triggerPanic;
  late final LastErrorCodeDart _lastErrorCode;

  bool _isInitialized = false;

  NativeAndroidCryptoProvider() {
    _initNativeLibrary();
  }

  void _initNativeLibrary() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libguffsuff_mobile_crypto_boundary.so');
    } else {
      throw UnsupportedError('NativeAndroidCryptoProvider is only supported on Android.');
    }

    _apiVersion = _lib.lookupFunction<NativeApiVersionC, NativeApiVersionDart>('boundary_api_version');
    _queryCapabilities = _lib.lookupFunction<QueryCapabilitiesC, QueryCapabilitiesDart>('query_capabilities');
    _createIdentityHandle = _lib.lookupFunction<CreateHandleC, CreateHandleDart>('create_test_identity_handle');
    _createSessionHandle = _lib.lookupFunction<CreateHandleC, CreateHandleDart>('create_test_session_handle');
    _createGroupHandle = _lib.lookupFunction<CreateHandleC, CreateHandleDart>('create_test_group_handle');
    _transformPayload = _lib.lookupFunction<TransformPayloadC, TransformPayloadDart>('transform_test_payload');
    _disposeHandle = _lib.lookupFunction<DisposeHandleC, DisposeHandleDart>('dispose_handle');
    _exportState = _lib.lookupFunction<ExportStateC, ExportStateDart>('export_opaque_test_state');
    _importState = _lib.lookupFunction<ImportStateC, ImportStateDart>('import_opaque_test_state');
    _triggerPanic = _lib.lookupFunction<TriggerPanicC, TriggerPanicDart>('trigger_controlled_test_panic');
    _lastErrorCode = _lib.lookupFunction<LastErrorCodeC, LastErrorCodeDart>('boundary_last_error_code');

    _isInitialized = true;
  }

  bool get isAvailable => _isInitialized;
  int get apiVersion => _apiVersion();
  int get lastErrorCode => _lastErrorCode();
  String get providerLabel => 'TEST PROVIDER — NO CONFIDENTIALITY OR AUTHENTICITY';

  @override
  ProviderCapabilityMap queryCapabilities() {
    final ptr = calloc<NativeCapabilityMapStruct>();
    try {
      final res = _queryCapabilities(ptr);
      if (res != 0) {
        throw ProviderUnavailableException('Native capability query failed with code: $res');
      }
      final map = ptr.ref;
      return ProviderCapabilityMap(
        supportsDirectMessaging: map.supportsDirectMessaging != 0,
        supportsGroupMessaging: map.supportsGroupMessaging != 0,
        supportedProtocolVersions: const [1],
        providerId: 'native-android-test-provider',
        providerVersion: '0.1.0-test',
        isTestProvider: map.isTestProvider != 0,
      );
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  Future<OpaqueIdentityHandle> initializeDeviceIdentity() async {
    final ptr = calloc<Uint64>();
    try {
      final res = _createIdentityHandle(ptr);
      if (res != 0) {
        throw Exception('Native createIdentityHandle failed: $res');
      }
      return OpaqueIdentityHandle(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  Future<OpaqueSessionHandle> establishOutboundSession(String recipientPrekeyBundle) async {
    final ptr = calloc<Uint64>();
    try {
      final res = _createSessionHandle(ptr);
      if (res != 0) {
        throw Exception('Native createSessionHandle failed: $res');
      }
      return OpaqueSessionHandle(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  Future<OpaqueGroupHandle> createGroupState(String groupId, List<String> memberDeviceIds) async {
    final ptr = calloc<Uint64>();
    try {
      final res = _createGroupHandle(ptr);
      if (res != 0) {
        throw Exception('Native createGroupHandle failed: $res');
      }
      return OpaqueGroupHandle(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  Future<List<int>> encryptPayload(OpaqueSessionHandle sessionHandle, List<int> plaintext) async {
    return _transformPayloadInternal(sessionHandle.handleId, plaintext);
  }

  @override
  Future<List<int>> decryptPayload(OpaqueSessionHandle sessionHandle, List<int> ciphertext) async {
    return _transformPayloadInternal(sessionHandle.handleId, ciphertext);
  }

  Future<List<int>> _transformPayloadInternal(int handleId, List<int> input) async {
    if (input.length > 10 * 1024 * 1024) {
      throw ArgumentError('OVERSIZED_BUFFER');
    }

    final inPtr = calloc<Uint8>(input.length);
    final outMaxLen = input.length + 1024;
    final outPtr = calloc<Uint8>(outMaxLen);
    final outLenPtr = calloc<IntPtr>();

    try {
      inPtr.asTypedList(input.length).setAll(0, input);
      final res = _transformPayload(handleId, inPtr, input.length, outPtr, outMaxLen, outLenPtr);
      if (res != 0) {
        if (res == -2) throw Exception('INVALID_HANDLE');
        if (res == -3) throw Exception('STALE_OR_DOUBLE_FREE');
        if (res == -5) throw Exception('BUFFER_TOO_SMALL');
        if (res == -6) throw ArgumentError('OVERSIZED_BUFFER');
        if (res == -9) throw Exception('ERR_HANDLE_TYPE_MISMATCH');
        throw Exception('Native transformPayload failed: $res');
      }

      final len = outLenPtr.value;
      return Uint8List.fromList(outPtr.asTypedList(len));
    } finally {
      calloc.free(inPtr);
      calloc.free(outPtr);
      calloc.free(outLenPtr);
    }
  }

  @override
  Future<void> disposeHandle(dynamic handle) async {
    int rawHandle = 0;
    if (handle is OpaqueIdentityHandle) rawHandle = handle.handleId;
    if (handle is OpaqueSessionHandle) rawHandle = handle.handleId;
    if (handle is OpaqueGroupHandle) rawHandle = handle.handleId;
    if (handle is int) rawHandle = handle;

    final res = _disposeHandle(rawHandle);
    if (res != 0) {
      if (res == -3) throw Exception('STALE_OR_DOUBLE_FREE');
      if (res == -2) throw Exception('INVALID_HANDLE');
      throw Exception('Native disposeHandle failed: $res');
    }
  }

  Future<Uint8List> exportOpaqueState() async {
    final maxLen = 64 * 1024;
    final outPtr = calloc<Uint8>(maxLen);
    final outLenPtr = calloc<IntPtr>();

    try {
      final res = _exportState(outPtr, maxLen, outLenPtr);
      if (res != 0) {
        throw Exception('Native exportOpaqueState failed: $res');
      }
      final len = outLenPtr.value;
      return Uint8List.fromList(outPtr.asTypedList(len));
    } finally {
      calloc.free(outPtr);
      calloc.free(outLenPtr);
    }
  }

  List<RestoredOpaqueHandle> parseExportedState(Uint8List stateData) {
    if (stateData.length < 8) return [];
    final byteData = ByteData.sublistView(stateData);
    final count = byteData.getUint32(4, Endian.little);
    final list = <RestoredOpaqueHandle>[];
    var offset = 8;
    for (var i = 0; i < count; i++) {
      if (offset + 10 > stateData.length) break;
      final handleId = byteData.getUint64(offset, Endian.little);
      final handleType = stateData[offset + 8];
      final isActive = stateData[offset + 9] != 0;
      offset += 10;
      list.add(RestoredOpaqueHandle(
        handleId: handleId,
        handleType: handleType,
        isActive: isActive,
      ));
    }
    return list;
  }

  Future<void> importOpaqueState(Uint8List stateData) async {
    final inPtr = calloc<Uint8>(stateData.length);
    try {
      inPtr.asTypedList(stateData.length).setAll(0, stateData);
      final res = _importState(inPtr, stateData.length);
      if (res != 0) {
        if (res == -7) throw Exception('VERSION_MISMATCH');
        if (res == -8) throw Exception('INVALID_STATE');
        throw Exception('Native importOpaqueState failed: $res');
      }
    } finally {
      calloc.free(inPtr);
    }
  }

  int triggerControlledPanic() {
    return _triggerPanic();
  }
}

class RestoredOpaqueHandle {
  final int handleId;
  final int handleType; // 1 = Identity, 2 = Session, 3 = Group
  final bool isActive;

  const RestoredOpaqueHandle({
    required this.handleId,
    required this.handleType,
    required this.isActive,
  });
}

