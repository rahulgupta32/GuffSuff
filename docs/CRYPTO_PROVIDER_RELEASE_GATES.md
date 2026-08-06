# Cryptographic Provider Release Safety Gates

> **Document Status**: Official Security Release Gate Specification (Phase 6A)

---

## 1. Automated Release Safety Gates

Production release builds (`pnpm build`, Flutter release APK/bundle) must automatically fail if any of the following conditions occur:

1. **Test Provider Inclusion**: A provider marked `isTestProvider: true` is compiled or loaded in release mode.
2. **Rejected Symbol Presence**: Identifiable symbols from rejected `openmls v0.8.1` or `libsignal v0.60.0` baselines are detected in native shared libraries.
3. **Debug Flag Bypass**: Environment variables such as `CRYPTO_SPIKE_MODE` or `INSECURE_TEST_MODE` are present in release binaries.
4. **Unsigned Dynamic Load**: Attempt to dynamically load unverified native binaries from writable paths.
5. **Plaintext Fallback**: Application attempts to degrade to unencrypted transport when secure messaging fails.
