# Phase 6 Cryptographic Decision Package

> **Document Status**: Official Phase 6 Architectural Decision Record (Post-Verification Audit)

---

## 1. Executive Summary & Track Decisions

- **Production Cryptographic Implementation**: `NOT AUTHORIZED`
- **Track A — One-to-One Direct Messaging**: `BLOCKED` (libsignal v0.60.0 historical baseline not recommended for production; pending evaluation of a supported direct-messaging provider).
- **Track B — MLS Group Messaging**: `BLOCKED` (OpenMLS v0.8.1 baseline REJECTED per ADR-061 due to unmitigated transitive advisories; pending official stable OpenMLS v0.9.0 release gate).
- **Custom Ratchet Implementation**: `PROHIBITED`

---

## 2. Component Status Matrix

- **OpenMLS Host Protocol Compatibility**: `PARTIAL PASS — 34-point group lifecycle and state persistence harness PASSED; 23/25 test vector suites PASSED.`
- **OpenMLS Dependency Advisory Gate**: `FAILED — Audit flagged RUSTSEC-2026-0173 (proc-macro-error2), RUSTSEC-2026-0212 (libcrux-secrets), RUSTSEC-2026-0207, and RUSTSEC-2026-0208 (libcrux-sha3).`
- **OpenMLS License-Policy Gate**: `PASSED — 0 license violations under explicit deny.toml allowlist.`
- **OpenMLS Production Baseline**: `REJECTED (ADR-061)`
- **Android Mobile Boundary**: `VERIFIED — Provider-neutral native boundary harness (guffsuff-android-neutral-boundary) compiled and verified for aarch64 and x86_64.`
- **Android Toolchain Status**: `PROVISIONED — Android SDK 35, NDK 26.3.11579264 (r26c), CMake 3.22.1, adb, emulator verified.`
- **Pull Request #9 Status**: `Draft / Blocked — Prohibited from merging.`
