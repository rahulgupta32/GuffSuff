# Cryptographic Spike Evidence Integrity Incident Report

> **Document Status**: Active Incident & Corrective Controls Record  
> **Incident Reference**: INC-2026-08-06-CRYPTO-EVIDENCE  
> **Status**: RESOLVED & CORRECTED

---

## 1. Executive Summary

During the Phase 6 pre-implementation setup for cryptographic compatibility spikes, synthetic placeholder commit SHAs and unverified artifact metadata were inadvertently introduced into evaluation documentation, test fixtures, checksum files, and Pull Request #9 descriptions.

This incident report documents the affected fields, root cause analysis, corrective actions taken, and updated verification controls.

---

## 2. Invalid Fields & Affected Files

| Field / Identifier | Invalid Reported Value | Verified Authentic Value | Impacted Documents / Files |
| :--- | :--- | :--- | :--- |
| **`libsignal` Commit SHA** | `d7c9f8a3e2b1049581a6c8e9f0123456789abcde` | `1b82e53c2be56f7ab0aef3650033f8fc4d584517` (`v0.60.0`) | `VERSIONS.md`, `LIBSIGNAL_COUNSEL_REVIEW_PACKET.md`, `spike_test.ts`, PR #9 |
| **OpenMLS Commit SHA** | `b4e2d1c0a9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4` | `47dbedecad0c1fd8eb5368d582250ebfcc1e1ce6` (`openmls-v0.8.1`) | `VERSIONS.md`, `spike_test.ts`, PR #9 |
| **`libsignal` Maven Group** | `net.signal:libsignal-client` | `org.signal:libsignal-client` | `VERSIONS.md`, `CHECKSUMS.md` |
| **OpenMLS Tag Format** | `openmls/v0.5.0` | `openmls-v0.8.1` | `VERSIONS.md`, `CRYPTO_SPIKE_ACCEPTANCE.md` |
| **Execution Statuses** | Prematurely labeled `PASSED` / simulated vectors | Reset to `NOT EXECUTED` | `CRYPTO_SPIKE_ACCEPTANCE.md`, `PHASE_6_CRYPTO_DECISION.md` |

---

## 3. Detection & Root Cause Analysis

- **Detection Method**: Automated verification against official upstream Git remote references (`git ls-remote --tags`) failed to resolve the reported 40-character SHAs.
- **Entry Vector**: Placeholder values were introduced during draft document structuring and passed into test assertions without live remote verification.
- **Validation Failure**: The contract test scanner verified SHA string length (40 chars) but did not perform `git cat-file -t` against official upstream clones.

---

## 4. Corrective Controls & Remediation

1. **Complete Removal**: Every instance of `d7c9...` and `b4e2...` has been purged across all files.
2. **Machine-Derived Git References**: All candidate commit SHAs are now machine-derived directly from `git ls-remote` / `git rev-parse`.
3. **Execution Status Reset**: All unexecuted native build, test, and persistence items are reset to `NOT EXECUTED`.
4. **Pull Request #9 Blocked**: PR #9 marked **DRAFT / BLOCKED**; merge prohibited until all native execution requirements pass.

---

## 5. Decision Impact Statement

**Zero architectural decisions relied on the synthetic placeholders.** No production code or application package was affected. Production cryptographic integration remains strictly **NOT AUTHORIZED**.
