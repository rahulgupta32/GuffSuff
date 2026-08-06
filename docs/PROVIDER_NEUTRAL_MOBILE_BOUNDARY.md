# Provider-Neutral Mobile Cryptographic Boundary Specification

> **Document Status**: Official Architecture Specification (Phase 6A Mobile Infrastructure)

---

## 1. Overview & Architectural Scope

This specification establishes a **provider-neutral, opaque native cryptographic boundary** for the GuffSuff Flutter mobile application (`apps/mobile`) and native host platforms (Android JNI / iOS FFI).

### Key Architectural Constraints

1. **No Embedded Production Protocol**: The boundary contains zero embedded production E2EE primitives (no libsignal v0.60.0, no OpenMLS v0.8.1).
2. **Opaque Handles**: All session states, private keys, and group credentials remain strictly inside native memory behind 64-bit opaque integer handles. Raw key material is **NEVER** exposed to Dart/JavaScript layers.
3. **Compile-Time Registration**: Cryptographic providers are registered strictly at build/compile time. No dynamic loading from writable disk locations is permitted.
4. **Production Rejection of Test Providers**: Test providers (`isTestProvider: true`) are hard-rejected in production builds.

---

## 2. Platform Transport & Safety Rules

- **Panic Containment**: All C/FFI entries wrap Rust code in `std::panic::catch_unwind`. Panics across FFI boundaries return negative error codes.
- **Byte Buffer Ownership**: Memory allocated by native providers must be freed by explicit native calls (`boundary_destroy_session`).
## 3. Current Execution Status

- **Android Emulator Tooling**: `PASSED — emulator executable verified`
- **Android Emulator Runtime**: `NOT EXECUTED`
- **Android Native Cross-Compilation**: `PASSED`
- **Android Native Runtime**: `NOT EXECUTED — no instrumentation or emulator execution evidence`
- **Flutter SDK**: `NOT INSTALLED or NOT VERIFIED`
- **Dart SDK**: `NOT VERIFIED`
- **Flutter Build**: `NOT EXECUTED`
- **Flutter Android Runtime**: `NOT EXECUTED`
- **Flutter Boundary-Contract Tests**: `PASSED IN TYPESCRIPT`
- **Flutter Runtime**: `NOT EXECUTED`
- **PR Recommendation**: `Continue implementation and review after Android and Flutter runtime gates pass.`

