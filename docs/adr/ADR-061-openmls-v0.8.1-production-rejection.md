# ADR-061: Rejection of OpenMLS v0.8.1 for Production Cryptographic Deployment

* **Status**: ACCEPTED — PRODUCTION REJECTION DECISION
* **Date**: 2026-08-06
* **Authors**: Technical Lead / Antigravity Pair
* **Deciders**: Security Architecture Committee

---

## 1. Context & Problem Statement

Phase 6 of the GuffSuff cryptographic evaluation evaluated OpenMLS v0.8.1 for MLS group key agreement (RFC 9420).

### Evaluated Candidate Baseline
- **Evaluated Version Tag**: `v0.8.1`
- **Evaluated Commit SHA**: `63c3619831dbdbccc9f7a70f3f3aae577a34ac09`
- **Host Test Counts**: 1,732 unit tests, 386 integration tests passed on Windows host.
- **Vector Results**: 23 of 25 mapped vector suites passed (2 unmapped).
- **State Lifecycle Harness**: 34 of 34 scenarios passed on host.
- **Windows Host Result**: `PARTIAL PASS` (Host protocol harness functional).
- **Android Cross-Compilation Result**: `PASSED — research baseline only` (`aarch64` and `x86_64` `.so` compiled).
- **Android Runtime Status**: `NOT EXECUTED — Android runtime instrumentation evidence not provided`.

### Advisory Findings
1. **RUSTSEC-2026-0212** (`libcrux-secrets v0.0.5`): High severity; constant-time swap/select on ARM64 (`select_u8` inline assembly `cmp`). Crate linked into `aarch64` Android `.so` artifact.
2. **RUSTSEC-2026-0207** (`libcrux-sha3 v0.0.8`): Medium severity; incremental portable SHAKE XOF `squeeze` function. Feature path enabled.
3. **RUSTSEC-2026-0208** (`libcrux-sha3 v0.0.8`): Medium severity; AVX2 SHAKE-256 indexing panic. Identifiable strings present on x86_64 target.
4. **RUSTSEC-2026-0173** (`proc-macro-error2 v2.0.1`): Informational; unmaintained procedural macro. Host build-time only; stripped from mobile `.so` artifacts.
5. **RUSTSEC-2021-0139** (`ansi_term v0.12.1`): Informational; deprecated test-only dependency.

### OpenMLS Pre-Release Evaluation
- **OpenMLS 0.9.0-rc.2**: `PRE-RELEASE RESEARCH ONLY — NOT A PRODUCTION CANDIDATE`. While `0.9.0-rc.2` upgrades `libcrux-secrets` to `0.0.6` and `libcrux-sha3` to `0.0.10`, breaking API changes occur across `OpenMlsProvider` traits, and `proc-macro-error2` remains present.

---

## 2. Decision Rationale & Explicit Prohibitions

1. **OpenMLS v0.8.1 Production Baseline**: **REJECTED**. OpenMLS v0.8.1 must NOT be used for production cryptographic deployment.
2. **Prohibition on Custom Patches**: Modifying upstream source or maintaining custom cryptographic forks is strictly prohibited.
3. **Prohibition on Dependency Overrides**: Using Cargo `[patch]` or `[replace]` to bypass security advisories without upstream maintainer verification is prohibited.
4. **Prohibition on Production Use**: Deploying or enabling rejected spike binaries or runtime feature flags in production builds is prohibited.
5. **Track Separation**:
   - **Track A (1-to-1 Direct Messaging)**: `BLOCKED` pending evaluation of a supported direct-messaging provider.
   - **Track B (MLS Group Messaging)**: `BLOCKED` pending the official stable release of `OpenMLS v0.9.0` satisfying all release gate criteria.
6. **Retained Research Value & Disposal**: Experimental code remains on isolated research branch `spike/crypto-provider-compatibility`. PR #9 will be closed without merging to prevent vulnerable lockfile imports into `main`.

