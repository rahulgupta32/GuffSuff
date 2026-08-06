# OpenMLS Dependency Remediation Analysis

> **Document Status**: Official Remediation Decision Record (Phase 6 Cryptographic Spike)

---

## 1. Executive Summary

An exhaustive evaluation of the OpenMLS dependency graph, upstream release tags, and crates.io metadata confirms that **no official patch release exists for OpenMLS v0.8.1 that resolves the flagged security advisories**.

### Outcome Classification:
**D. No supported remediation exists for the selected OpenMLS version (v0.8.1).**
**E. OpenMLS candidate must remain REJECTED / BLOCKED for production.**

---

## 2. Upstream Release Comparison

| Package | Evaluated Version | Upstream Latest Stable | Upstream Latest Pre-release | Status |
|---------|-------------------|------------------------|-----------------------------|--------|
| `openmls` | `v0.8.1` | `v0.8.1` | `v0.9.0-rc.2` | No `0.8.x` patch release available |
| `openmls_rust_crypto` | `v0.5.1` | `v0.5.1` | `v0.6.0-rc.2` | Locked to `hpke-rs 0.6.1` |
| `hpke-rs` | `v0.6.1` | `v0.6.1` | N/A | Pins `libcrux-sha3 0.0.8` & `libcrux-secrets 0.0.5` |
| `proc-macro-error2` | `v2.0.1` | `v2.0.1` | N/A | Unmaintained fork with zero upgrade path |

---

## 3. Detailed Advisory Path Analysis

### 1. `proc-macro-error2 v2.0.1` (RUSTSEC-2026-0173)
* **Path**: `proc-macro-error2 v2.0.1` -> `hax-lib-macros v0.3.6` -> `hax-lib v0.3.6` -> `core-models v0.0.5` -> `libcrux-intrinsics v0.0.6` -> `libcrux-sha3 v0.0.8` -> `hpke-rs v0.6.1` -> `openmls_rust_crypto v0.5.1` -> `openmls v0.8.1`
* **Role**: Build-time procedural macro (host only, stripped from compiled mobile `.so` shared libraries).
* **Remediation Status**: **UNRESOLVED in v0.8.1**. The crate is unmaintained. OpenMLS maintainers are migrating to `manyhow` in `openmls v0.9.0`.

### 2. `libcrux-secrets v0.0.5` (RUSTSEC-2026-0212)
* **Path**: `libcrux-secrets v0.0.5` -> `libcrux-traits v0.0.6` -> `libcrux-sha3 v0.0.8` -> `hpke-rs v0.6.1` -> `openmls_rust_crypto v0.5.1` -> `openmls v0.8.1`
* **Role**: Runtime cryptographic secret operations on `aarch64`.
* **Remediation Status**: **BLOCKED in v0.8.1**. `hpke-rs v0.6.1` hard-codes dependency bounds on `libcrux-secrets 0.0.5`, preventing `cargo update` from advancing to `0.0.6+`.

### 3. `libcrux-sha3 v0.0.8` (RUSTSEC-2026-0207 & RUSTSEC-2026-0208)
* **Path**: `libcrux-sha3 v0.0.8` -> `hpke-rs v0.6.1` -> `openmls_rust_crypto v0.5.1` -> `openmls v0.8.1`
* **Role**: Runtime SHAKE-256 / SHAKE-128 hashing on host & mobile targets.
* **Remediation Status**: **BLOCKED in v0.8.1**. `hpke-rs v0.6.1` hard-codes dependency bounds on `libcrux-sha3 0.0.8`, preventing `cargo update` from advancing to `0.0.10+`.

---

## 4. Remediation Recommendation

1. **Production Integration Gate**: `BLOCKED / NOT AUTHORIZED`.
2. **Upstream Monitoring**: Track the official release of `openmls v0.9.0` (stable) which updates the cryptographic provider stack to `libcrux 0.0.10+` and replaces `proc-macro-error2`.
3. **Manual Overrides**: Do NOT apply unsafe `[patch.crates-io]` or force manual Cargo.lock overrides that break upstream SemVer compatibility.
