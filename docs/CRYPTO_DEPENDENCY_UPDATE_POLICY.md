# Cryptographic Dependency Update & Security Advisory Policy

> **Document Status**: Active Policy Specification for OpenMLS & Cryptographic Components

---

## 1. Overview & Policy Directives

This document defines the security advisory monitoring, classification, exception approval, and dependency updating rules for cryptographic dependencies in GuffSuff.

### Principles:
1. **Zero Unvetted Vulnerabilities**: No dependency with a high or critical CVE / RustSec advisory is allowed in production binaries.
2. **Exact Advisory Attribution**: Adversarial security reports must use exact RustSec advisory IDs. Distinguish between original unmaintained crates and maintained/unmaintained forks.
3. **Spike Exceptions Are Non-Production**: Broad exceptions or spike-only allowances in `deny.toml` do NOT grant production clearance.

---

## 2. Verified RustSec Advisory Inventory

| Advisory ID | Crate Name | Crate Version | Dependency Path | Status / Severity | Runtime / Build-time | Production Impact | Mitigation / Migration Plan |
|-------------|------------|---------------|-----------------|-------------------|----------------------|-------------------|-----------------------------|
| **RUSTSEC-2026-0173** | `proc-macro-error2` | `v2.0.1` | `proc-macro-error2` -> `hax-lib-macros` -> `hax-lib` -> `core-models` -> `libcrux` -> `hpke-rs` -> `openmls_rust_crypto` -> `openmls` | Unmaintained (Informational) | Build-time (proc-macro) | **NONE** (host-only build dependency stripped from native mobile binaries) | Monitor upstream `libcrux` and OpenMLS for migration to `manyhow` or `proc-macro2-diagnostics`. |
| **RUSTSEC-2024-0370** | `proc-macro-error` | N/A | Not in tree | Unmaintained (Informational) | N/A | **NONE** (not used) | N/A. `proc-macro-error` is the original unmaintained crate. |
| **RUSTSEC-2026-0205** | `libcrux-secrets` | `v0.0.5` | `libcrux-secrets` -> `libcrux-traits` -> `hpke-rs` -> `openmls_rust_crypto` -> `openmls` | Vulnerability (High) | Runtime | **MITIGATED** in spike | Transitive update available. Upgrade to `libcrux-secrets >=0.0.6`. |
| **RUSTSEC-2026-0207** | `libcrux-sha3` | `v0.0.8` | `libcrux-sha3` -> `hpke-rs` -> `openmls_rust_crypto` -> `openmls` | Vulnerability (Medium) | Runtime | **MITIGATED** in spike | Transitive update available. Upgrade to `libcrux-sha3 >=0.0.10`. |
| **RUSTSEC-2026-0208** | `libcrux-sha3` | `v0.0.8` | `libcrux-sha3` -> `hpke-rs` -> `openmls_rust_crypto` -> `openmls` | Vulnerability (Medium) | Runtime | **MITIGATED** in spike | Transitive update available. Upgrade to `libcrux-sha3 >=0.0.10`. |

---

## 3. OpenMLS Dependency Path Analysis (`proc-macro-error2`)

1. **Default Build Inclusion**: `proc-macro-error2` is included when using the default `openmls_rust_crypto` provider of `openmls v0.8.1`.
2. **Feature Gating**: It is pulled via `hpke-rs` -> `libcrux` -> `hax-lib` -> `hax-lib-macros` (proc-macro).
3. **Android Release Artifacts**: Procedural macro code (`proc-macro-error2`) runs strictly on the compilation host and is **omitted** from compiled mobile `.so` shared libraries.
4. **Crypto Provider Alternates**: Alternate crypto providers (e.g. `openmls_evercrypt_crypto`) use different backends, but `openmls_rust_crypto` remains the primary target for Rust cross-compilation.
5. **Security/Standards Impact of Disabling**: Disabling `openmls_rust_crypto` would break MLS ciphersuite operations.
6. **Maintainer Upgrades**: OpenMLS maintainers are actively tracking `libcrux` and `hax-lib` upstream updates.
7. **Patch Releases**: `proc-macro-error2 v2.0.1` has no patched release because it is an unmaintained fork.
8. **External Reviewer Acceptance**: Informational unmaintained proc-macro advisories are acceptable under documented residual risk review when zero runtime code is exposed.
9. **Build vs. Runtime**: Strictly **build-time procedural macro**.
10. **Reproducible Builds**: Crates are cached in `Cargo.lock` and `crates.io` index, maintaining build reproducibility.

---

## 4. Emergency Patch & Monitoring Plan

1. **Weekly Advisory Scans**: CI runs `cargo deny check advisories` on every PR.
2. **Transitive Dependency Pinning**: `Cargo.lock` must be committed and audited.
3. **Prohibition of Unvetted Forks**: No local patching with unmaintained or unvetted third-party forks is allowed.
