# Mobile & Backend Cryptographic Platform Compatibility

> **Document Status**: Platform Integration & Hardware Security Matrix (Corrected Key Wrapping Boundaries)

---

## 1. Precise Hardware Security & Key Wrapping Architecture

It is critical to maintain precise platform security boundaries:

1. **iOS Keychain & Secure Enclave**: Keychain is a protected credential and secret storage service. Secure Enclave can generate and operate with supported non-exportable key types. Whether a SQLCipher database key is directly represented by a Secure Enclave-backed key depends on the wrapping architecture and supported algorithms. **Arbitrary SQLCipher passphrases and protocol-state blobs are NOT stored directly inside Secure Enclave.** A practical design stores or wraps a database key using Keychain access controls (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
2. **Android KeyStore & StrongBox**: KeyStore can protect supported non-exportable master keys. StrongBox is optional and device-dependent (Pixel 3+, Knox). **Arbitrary SQLCipher state remains in encrypted application storage.**
3. **Encrypted Local Database (SQLite)**: Stores all protocol state (identity records, prekeys, session ratchets, group TreeKEM epochs).

---

## 2. Technical Compatibility Matrix

| Platform | Master Key Wrapping Control | Protocol State Persistence | FFI / Bridge Binding Layer | Supported Architectures |
| :--- | :--- | :--- | :--- | :--- |
| **Android Mobile** | KeyStore (TEE / StrongBox) | Local Encrypted SQLite | Dart FFI -> JNI / Native C-shared lib | `arm64-v8a`, `x86_64` |
| **iOS Mobile** | Keychain (Secure Enclave wrapping) | Local Encrypted SQLite | Dart FFI -> Objective-C / Swift C-bridge | `arm64` |
| **Node.js API/Worker** | Environment Secrets / KMS | PostgreSQL (`002_schema`) | Native C++ addon or WebAssembly | `x64`, `arm64` |
