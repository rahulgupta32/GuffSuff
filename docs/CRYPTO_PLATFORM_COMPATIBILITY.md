# Mobile & Backend Cryptographic Platform Compatibility

> **Document Status**: Platform Integration & Hardware Security Matrix

---

## Technical Compatibility Matrix

| Platform | Native KeyStore | Hardware Encryption Acceleration | FFI Binding Layer | Target Architecture |
| :--- | :--- | :--- | :--- | :--- |
| **Android Mobile** | Android KeyStore (TEE / StrongBox) | AES-NI, ARMv8 Cryptographic Extensions | Dart FFI -> JNI / C-shared lib | `arm64-v8a`, `x86_64` |
| **iOS Mobile** | iOS Keychain (Secure Enclave) | ARMv8.2 Crypto Extensions | Dart FFI -> Objective-C / Swift C-bridge | `arm64` |
| **Node.js API/Worker** | Node.js `crypto` (OpenSSL 3.0) | CPU-native AES-GCM / SHA-256 | Native C++ addon or WebAssembly | `x64`, `arm64` |
