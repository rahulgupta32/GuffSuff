# Cryptographic Compatibility Spike Acceptance Criteria & Evaluation Matrix

> **Document Status**: Reset Execution Matrix (Post-Incident Verification Reset)

---

## 1. Candidate Evaluation Status Summary

| Evaluation Gate | Candidate A (`libsignal`) | Candidate B (OpenMLS) | Status Vocabulary Standard |
| :--- | :--- | :--- | :--- |
| **Dependency Pinning & Checksums** | `PASSED` | `PASSED` | Machine-derived commit SHAs & checksums recorded in `VERSIONS.md` & `CHECKSUMS.md`. |
| **Android Build Verification** | `NOT EXECUTED` | `NOT EXECUTED` | Pending native Gradle / NDK build execution. |
| **iOS Build Verification** | `NOT EXECUTED` | `NOT EXECUTED` | Pending native Xcode / Swift compilation execution. |
| **Flutter Bridge Feasibility** | `NOT EXECUTED` | `NOT EXECUTED` | Pending native platform channel / FFI execution on device/emulator. |
| **Official Upstream Unit Tests** | `NOT EXECUTED` | `NOT EXECUTED` | Upstream test harness pending execution. |
| **Official Test Vectors** | `NOT EXECUTED` | `NOT EXECUTED` | Official KAT test vectors pending execution. |
| **State Persistence Verification** | `NOT EXECUTED` | `NOT EXECUTED` | Transactional SQLite native storage adapter pending execution. |
| **Native Crash Handling** | `NOT EXECUTED` | `NOT EXECUTED` | Native unwinding & exception catching pending execution. |
| **Native Concurrency** | `NOT EXECUTED` | `NOT EXECUTED` | Multi-threaded session ratchet execution pending test. |
| **Native Memory Safety** | `NOT EXECUTED` | `NOT EXECUTED` | Zeroization & Valgrind/ASan checks pending execution. |
| **Binary Footprint Measurement** | `NOT EXECUTED` | `NOT EXECUTED` | Exact APK / AAB / Framework delta measurement pending build. |
| **Dependency & Supply Chain Audit** | `PASSED` | `PASSED` | Lockfiles & SBOM generated; zero critical CVEs found. |
| **License Compliance Audit** | `BLOCKED` | `PASSED` | `libsignal` AGPL-3.0 copyleft & App Store terms require formal legal approval. |
| **Production Isolation Verification** | `PASSED` | `PASSED` | Production manifest & destructive removal tests passed 100%. |
| **External Cryptographic Audit Gate** | `BLOCKED` | `BLOCKED` | Independent 3rd-party cryptographic review required prior to production authorization. |

---

## 2. Mandatory Production Gates

Production integration remains **BLOCKED** for both candidates until legal review (`libsignal`), external cryptographic audit, and all evaluation gates achieve `PASSED` status.
