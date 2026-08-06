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

- **Android Emulator Tooling**: `PASSED — emulator executable and test_disposable_avd verified`
- **Android Emulator Runtime**: `PASSED — booted API 35 x86_64 AVD, adb connectivity confirmed`
- **Android Native Cross-Compilation**: `PASSED` (`guffsuff-android-neutral-boundary` compiled for `aarch64` and `x86_64`)
- **Android Native Runtime**: `PASSED — APK installed and executed on emulator-5554 (com.guffsuff.mobile PID 8417)`
- **Flutter SDK**: `PASSED — Flutter 3.44.8 (stable) installed & verified via flutter doctor`
- **Dart SDK**: `PASSED — Dart 3.12.2 installed & verified`
- **Flutter Build**: `PASSED — flutter build apk --debug assembled app-debug.apk`
- **Flutter Android Runtime**: `PASSED — Impeller engine & Dart VM initialized on Android 15 emulator`
- **Flutter Boundary-Contract Tests**: `PASSED — 7/7 Flutter unit & safety contract tests passed`
- **PR Recommendation**: `Ready for PR review & merger into main.`


