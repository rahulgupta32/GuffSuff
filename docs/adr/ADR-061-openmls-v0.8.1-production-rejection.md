# ADR-061: Rejection of OpenMLS v0.8.1 for Production Cryptographic Deployment

* **Status**: Accepted (Rejection Decision)
* **Date**: 2026-08-06
* **Authors**: Technical Lead / Antigravity Pair
* **Deciders**: Security Architecture Committee

---

## Context & Problem Statement

Phase 6 of the GuffSuff cryptographic evaluation evaluated OpenMLS v0.8.1 for MLS group key agreement (RFC 9420). While OpenMLS v0.8.1 successfully passed host-side unit testing, test vector suite execution (23/25 mapped suites passed), and a 34-scenario end-to-end group lifecycle harness, dependency auditing (`cargo-deny` / `cargo-audit`) identified unmitigated runtime security vulnerabilities in its transitive dependency tree (`libcrux-secrets v0.0.5`, `libcrux-sha3 v0.0.8`) and an unmaintained procedural macro crate (`proc-macro-error2 v2.0.1`).

---

## Decision Drivers

1. **Unmitigated Runtime Vulnerabilities**: `RUSTSEC-2026-0212` (`libcrux-secrets v0.0.5` constant-time swap/select on ARM64) directly impacts mobile `aarch64` binaries.
2. **Absence of Upstream Patch**: `openmls v0.8.1` is the latest stable release. No `v0.8.2+` patch release exists upstream to loosen dependency bounds on `hpke-rs v0.6.1`.
3. **No Unapproved Overrides**: Manual Cargo.lock patching or unvetted dependency overrides are prohibited by project security policy.
4. **Clean Mobile Architecture**: A provider-neutral Android native boundary harness was verified to allow mobile UI development to proceed independently of the crypto provider decision.

---

## Decision

1. **OpenMLS v0.8.1 Production Baseline**: **REJECTED**. OpenMLS v0.8.1 must NOT be used for production cryptographic deployment.
2. **Track Separation**:
   - **Track A (1-to-1 Direct Messaging)**: `BLOCKED` pending evaluation of a supported direct-messaging provider.
   - **Track B (MLS Group Messaging)**: `BLOCKED` pending the official stable release of `OpenMLS v0.9.0` with updated `libcrux` dependencies.
3. **Reconsideration Conditions**: OpenMLS will be re-evaluated when an official stable release satisfies all 14 criteria defined in `docs/OPENMLS_UPSTREAM_RELEASE_GATE.md`.
4. **Pull Request #9 Disposition**: Pull Request #9 shall remain **Draft / Blocked** and subsequently closed without merging to prevent vulnerable lockfile imports.

---

## Consequences

* **Positive**: Prevents deployment of vulnerable constant-time assembly routines and unmaintained dependencies to mobile clients. Maintains strict compliance with security policies.
* **Negative**: Delays production E2EE group messaging deployment until upstream OpenMLS v0.9.0 reaches general availability.
* **Mitigation**: Mobile engineering proceeds using the provider-neutral boundary harness (`guffsuff-android-neutral-boundary`).
