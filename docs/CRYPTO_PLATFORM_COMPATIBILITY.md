# Mobile & Backend Cryptographic Platform Compatibility

> **Document Status**: Platform Integration & Hardware Security Matrix (Corrected Storage Boundaries)

---

## 1. Storage & Hardware Security Architecture

It is critical to distinguish between hardware key protection and protocol state storage:

1. **Android KeyStore (TEE / StrongBox)**: Generates and protects non-exportable master database encryption keys. Hardware availability (StrongBox vs TEE) varies by device model.
2. **iOS Keychain & Secure Enclave**: Keychain securely stores master database encryption keys and credential references. Secure Enclave protects non-exportable key generation and operations.
3. **Encrypted Local Database (SQLite)**: Stores all protocol state (identity records, prekeys, session ratchets, group TreeKEM epochs). **Neither Secure Enclave nor Android KeyStore directly stores arbitrary protocol state.** The SQLite database is encrypted at rest using SQLCipher with master keys derived from KeyStore/Keychain.

---

## 2. Technical Compatibility Matrix

| Platform | Master Key Protection | Protocol State Persistence | FFI / Bridge Binding Layer | Supported Architectures |
| :--- | :--- | :--- | :--- | :--- |
| **Android Mobile** | Android KeyStore (TEE / StrongBox) | Local Encrypted SQLite | Dart FFI -> JNI / Native C-shared lib | `arm64-v8a`, `x86_64` |
| **iOS Mobile** | iOS Keychain (Secure Enclave) | Local Encrypted SQLite | Dart FFI -> Objective-C / Swift C-bridge | `arm64` |
| **Node.js API/Worker** | Environment Secrets / KMS | PostgreSQL (`002_schema`) | Native C++ addon or WebAssembly | `x64`, `arm64` |
