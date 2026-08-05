# Cryptographic Compatibility Spike Acceptance Criteria

> **Document Status**: Spike Evaluation & Decision Gates

---

## Mandatory Criteria for Spike Evaluation

A cryptographic evaluation spike (Candidate A: `libsignal`, Candidate B: `OpenMLS`) passes Phase 6 pre-implementation evaluation ONLY if it fulfills all of the following:

1. **Technical Build Compatibility**: Compiles cleanly across target architectures (`x86_64`, `arm64`).
2. **Platform Integration**: Successful native Android and iOS build verification.
3. **Flutter Bridge Feasibility**: Demonstrates safe Dart FFI / platform channel invocation without leaking raw private key strings.
4. **Official Test Vectors**: Executes 100% of official upstream test vectors without custom primitive modifications.
5. **State Persistence Assessment**: Defines atomic transactional storage interfaces.
6. **Binary Footprint**: Measures exact `.so` / `.framework` / `.dylib` size increase.
7. **Complete Isolation**: Proves 0 imports in production packages (`@guffsuff/api`, `@guffsuff/worker`, `apps/mobile/lib`).
8. **Removal Procedure**: Provides clean, verified script to remove all spike manifests and native binaries.

*Passing a spike does NOT authorize production deployment. Production integration requires formal external security audit and legal approval.*
