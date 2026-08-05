# Cryptographic Compatibility Spike Acceptance Criteria & Evaluation Matrix

> **Document Status**: Spike Evaluation & Decision Gates (Strict Status Vocabulary Enforced)

---

## 1. Candidate Evaluation Status Summary

| Evaluation Gate | Candidate A (`libsignal`) | Candidate B (OpenMLS) | Status Vocabulary Standard |
| :--- | :--- | :--- | :--- |
| **Dependency Pinning & Checksums** | `PASSED` | `PASSED` | Exact commit SHAs & checksums recorded in `VERSIONS.md` & `CHECKSUMS.md`. |
| **Android Build Verification** | `UNDER EVALUATION` | `UNDER EVALUATION` | Isolated Gradle cross-compilation in progress. |
| **iOS Build Verification** | `UNDER EVALUATION` | `UNDER EVALUATION` | Isolated Swift / C-framework compilation in progress. |
| **Flutter Bridge Feasibility** | `UNDER EVALUATION` | `UNDER EVALUATION` | Dart FFI / Platform channels under evaluation; raw keys strictly opaque. |
| **Official Upstream Unit Tests** | `NOT EXECUTED` | `NOT EXECUTED` | Test harnesses configured; execution in progress. |
| **Official Test Vectors** | `NOT EXECUTED` | `NOT EXECUTED` | Upstream test vector execution pending harness run. |
| **State Persistence Verification** | `UNDER EVALUATION` | `UNDER EVALUATION` | Transactional SQLite storage interface under evaluation. |
| **Crash & Recovery Handling** | `UNDER EVALUATION` | `UNDER EVALUATION` | Exception and unwinding panic catchers under test. |
| **Concurrency & Memory Safety** | `UNDER EVALUATION` | `UNDER EVALUATION` | Native zeroization & AddressSanitizer checks under test. |
| **Binary Footprint Measurement** | `NOT EXECUTED` | `NOT EXECUTED` | Exact APK / AAB / Framework delta measurement pending build artifacts. |
| **Dependency & Supply Chain Audit** | `PASSED` | `PASSED` | Lockfiles & SBOM generated; zero critical CVEs found. |
| **License Compliance Audit** | `BLOCKED` | `PASSED` | `libsignal` AGPL-3.0 copyleft & App Store terms require formal legal approval. |
| **Production Isolation Verification** | `PASSED` | `PASSED` | Production manifest & destructive removal tests passed 100%. |
| **External Cryptographic Audit Gate** | `BLOCKED` | `BLOCKED` | Independent 3rd-party cryptographic review required prior to production authorization. |

---

## 2. Mandatory Production Gates

Production integration remains **BLOCKED** for both candidates until legal review (`libsignal`), external cryptographic audit, and all evaluation gates achieve `PASSED` status.
