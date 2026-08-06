# OpenMLS Host Compatibility Evaluation Result

> **Document Status**: Official Host Evaluation Record (Phase 6 Cryptographic Compatibility Spike)

---

## 1. Environment & Target Baseline

- **OpenMLS Version**: `v0.8.1` (Commit / Crate: `openmls v0.8.1`)
- **Rust Toolchain**: `rustc 1.97.1 (8bab26f4f 2026-07-14)` (Stable) & `nightly-x86_64-pc-windows-msvc` (Miri)
- **Host Operating System**: Windows 11 x86_64
- **Ciphersuite Evaluated**: `MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519` (Ciphersuite 1)

---

## 2. Host Verification Results

| Metric / Evaluation Area | Result | Status Details |
|--------------------------|--------|----------------|
| **Workspace Test Counts** | 1,732 unit tests, 386 integration tests passed | All core OpenMLS workspace tests passed on Windows host. |
| **Failed Environment Packages** | `interop_client`, `openmls-wasm` | Expected environment failures (gRPC server / WASM browser runners missing). |
| **Vector Suite Coverage** | 23/25 Suites PASSED, 2 Unmapped | 23 mapped vector suites passed. `deserialization.json` & `kat_tree_kem_openmls.json` lack upstream host runners. |
| **34-Point Lifecycle Harness** | 34 / 34 Scenarios PASSED | Ephemeral state persistence, Welcome processing, message protection, restart, and history isolation verified. |
| **Storage Provider Used** | Ephemeral File Persistence & In-Memory | EPhemeral JSON file persistence with atomic write-and-rename semantics verified. |
| **Concurrency Strategy** | Single-Writer Mutex Locking | Multi-process / multi-thread locking enforced by application wrapper. |
| **Corruption Handling** | Error Handled / Rejection | Malformed JSON and tampered checksum state reloads cleanly rejected. |
| **Cargo Audit Result** | FAILED | Flagged RUSTSEC-2026-0173, RUSTSEC-2026-0212, RUSTSEC-2026-0207, RUSTSEC-2026-0208. |
| **Cargo Deny Advisory Result** | FAILED | Unmitigated security vulnerabilities in `libcrux-sha3`, `libcrux-secrets`, and unmaintained `proc-macro-error2`. |
| **Cargo Deny License Result** | PASSED | All 188 transitive dependencies satisfy explicit permissive allowlist (`deny.toml`). |
| **Miri Scope & Limitations** | PARTIAL | State serialization unit test PASSED (0.36s); full protocol harness BLOCKED by `SystemTime::now` Windows FFI call in KeyPackage lifetime creation. |

---

## 3. Mandatory Gate & Evidence Summary

- **HOST COMPATIBILITY**: `PARTIAL PASS`
- **DEPENDENCY ADVISORY GATE**: `FAILED`
- **LICENSE POLICY GATE**: `PASSED` (under explicit `deny.toml` allowlist)
- **OPENMLS PRODUCTION BASELINE**: `REJECTED (ADR-061)`
- **BUILT-ARTIFACT SBOM**: `PARTIAL — source dependency SBOM and native artifact inspection completed; complete built-artifact SBOM not yet generated.`
- **PROVIDER-NEUTRAL ANDROID CROSS-COMPILATION**: `PASSED`
- **PROVIDER-NEUTRAL ANDROID RUNTIME**: `NOT EXECUTED — Android runtime instrumentation evidence not provided`
- **REJECTED OPENMLS V0.8.1 ANDROID CROSS-COMPILATION**: `PASSED — research baseline only`
- **REJECTED OPENMLS V0.8.1 ANDROID RUNTIME**: `NOT EXECUTED — Android runtime instrumentation evidence not provided`
- **OPENMLS 0.9.0-RC.2 EVALUATION**: `PRE-RELEASE RESEARCH ONLY — NOT A PRODUCTION CANDIDATE`
- **PRODUCTION INTEGRATION**: `NOT AUTHORIZED`

