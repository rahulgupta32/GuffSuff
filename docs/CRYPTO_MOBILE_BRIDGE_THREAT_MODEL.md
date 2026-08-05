# Mobile Native Cryptographic Bridge Threat Model

> **Document Status**: FFI & Platform Channel Security Assessment

---

## 1. Identified FFI & Native Bridge Vectors

| Threat Vector | Risk Description | Mandatory Mitigation Strategy |
| :--- | :--- | :--- |
| **Dart-to-Native Type Confusion** | Passing invalid memory pointers or struct layouts across FFI boundary. | Enforce strict C-struct typings (`ffi.Struct`) and versioned ABI wrappers. |
| **Buffer Length Mismatch** | Native function writing past allocated Dart memory buffer. | Explicit buffer length parameters passed and validated before native call. |
| **Rust Panic Across FFI** | Uncaught Rust panic unwinding across C-ABI boundary causing undefined behavior/crash. | Wrap all Rust FFI entry points in `catch_unwind()` returning error code structs. |
| **Secret Copies in Dart Heap** | Long-lived key strings garbage-collected without zeroization in Dart VM heap. | **Prohibit storing raw private keys in Dart `String` objects**. Use opaque handles or `Pointer<Uint8>` zeroized via `free()`. |
| **Native Heap Secret Leakage** | C/Rust key buffers un-zeroized after session calculations. | Use `zeroize` crate in Rust and `sodium_memzero` for native buffers on drop. |
| **JNI / Swift Bridge Misuse** | Exception leakage or unmanaged object retention across Android JNI / iOS Swift bridges. | Fail-closed exception handlers; return opaque integer handles instead of raw key bytes. |
| **Native Library Substitution** | Attacker replacing `.so` / `.dylib` binary in dynamic link path. | Code signing, integrity verification, and Play Store / App Store bundle signing. |

---

## 2. Strict Key Handling Rule

> **CRITICAL**: Private keys MUST NOT be represented as plain human-readable Dart `String` objects. All key material crossing mobile FFI boundaries MUST use opaque native pointers or zeroizable byte buffers (`Uint8List` backed by pinned native memory).
