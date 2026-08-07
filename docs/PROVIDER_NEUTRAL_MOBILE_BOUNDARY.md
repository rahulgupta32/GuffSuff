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
- **Byte Buffer Ownership**: Memory allocated by native providers must be freed by explicit native calls (`dispose_handle`).

---

## 3. Verified Execution Status

- **Android Emulator Tooling**: `PASSED — emulator executable and test_disposable_avd verified`
- **Android Emulator Runtime**: `PASSED — booted API 35 x86_64 AVD, adb connectivity confirmed`
- **Flutter Application Smoke Test**: `PASSED — APK installed & launched on emulator-5554`
- **Dart Provider-Neutral Contract Tests**: `PASSED — 7/7 unit & safety tests passed`
- **Native Rust Crate Unit Tests**: `PASSED — 4/4 host unit tests passed`
- **Native Android Boundary Target Builds**: `PASSED — aarch64-linux-android & x86_64-linux-android compiled`
- **Native Android Boundary Runtime**: `PASSED — libguffsuff_mobile_crypto_boundary.so loaded on emulator-5554`
- **Flutter-to-Native Handshake**: `PASSED — API version 1 handshake verified`
- **Provider-Neutral Runtime Lifecycle**: `PASSED — 17 integration test groups (26 scenarios) passed on Android emulator`
- **Process Restart & State Reload**: `PASSED — verified app force-stop (am force-stop) clears active handle state`
- **Test-Provider Production Rejection**: `PASSED — assertProductionProviderSafety enforces fail-closed state in release mode`
- **Release Artifact Exclusion**: `PASSED — release APK (45.4MB) and AAB (45.1MB) zero prohibited symbol leakage verified`
- **Built-Artifact SBOMs**: `PASSED — 5 CycloneDX 1.5 JSON SBOM manifests generated and validated`
