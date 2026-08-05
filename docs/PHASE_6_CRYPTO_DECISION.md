# Phase 6 — Cryptographic Decision Package & Architecture Framework

> **Document Status**: Proposal & Evaluation Guidelines (Pre-Integration Phase 6)

---

## 1. Executive Summary

This document defines the decision framework for integrating production end-to-end encryption (E2EE) into GuffSuff Phase 6. In accordance with project security policy, **no production cryptographic code or provider integration has been introduced during Phase 5**.

---

## 2. Core Cryptographic Topics & Technical Evaluation Matrix

| Topic ID | Cryptographic Concern | Evaluation Standard & Boundary |
| :--- | :--- | :--- |
| **1** | **1:1 Asynchronous Session Establishment** | Extended Triple Diffie-Hellman (X3DH) / PQX3DH or KEM-based key agreement handling offline initial message setup. |
| **2** | **1:1 Multi-Device Session Management** | Pairwise Signal sessions per recipient device vs sender device fan-out encryption. |
| **3** | **Direct-Message Ratcheting** | Double Ratchet Algorithm (Diffie-Hellman ratchet + symmetric key ratchet) offering Forward Secrecy (FS) and Post-Compromise Security (PCS). |
| **4** | **Device Verification** | Safety numbers / QR code verification based on cryptographic identity keys (`identity_key_pub`). |
| **5** | **Key-Change Warnings** | Explicit security notifications on untrusted identity key replacement (`untrusted_key_change_event`). |
| **6** | **Group Key Agreement** | Sender Keys / TreeKEM (MLS RFC 9420) key distribution for multi-party conversations. |
| **7** | **Group Membership Changes** | Immediate key epoch increment on member add/remove enforcing backward and forward secrecy. |
| **8** | **Attachment Key Transport** | Out-of-band media payload encryption using AES-256-GCM with key & digest transport inside envelope payload. |
| **9** | **Protocol Versioning** | Version field in envelope header (`protocolVersion: 2`) with strict fail-closed downgrade protection. |
| **10** | **Post-Quantum Roadmap** | Migration path to hybrid ML-KEM-768 (Kyber768) + X25519 key exchange (PQX3DH). |
| **11** | **Backup & Recovery** | Client-side encrypted backup blob with user-managed passphrase/passkey derivation (Argon2id). Server stores 0 unencrypted backups. |
| **12** | **Flutter Integration** | FFI native bridge wrappers (`libsignal_ffi`, `openmls_ffi`, or `sodium_ffi`). |
| **13** | **Android Native Integration** | Android KeyStore backed master key storage with hardware-backed Keystore security (TEE/StrongBox). |
| **14** | **iOS Native Integration** | iOS Keychain backed master key storage with Secure Enclave protection. |
| **15** | **Licensing & Commercial Use** | AGPLv3 vs MIT/Apache 2.0 evaluation for client and server components. |
| **16** | **External Maintenance & Support** | Active community maintainers, corporate backing, release cadence, and dependency stability. |
| **17** | **Independent Audit Scope** | Third-party cryptographic audit requirement covering state machines, key lifecycles, and bridge bindings. |
| **18** | **Migration Risk** | Seamless transition from Phase 5 opaque placeholders (`protocolVersion: 1`) to E2EE envelopes (`protocolVersion: 2`). |
| **19** | **Rollback Limitations** | Explicit prohibition on protocol downgrade attacks once E2EE session established. |
| **20** | **Interoperability Tests** | Cross-platform test vectors validating Flutter, Android, iOS, and Node.js test harness implementations. |

---

## 3. Candidate Mandatory Warnings

### A. Signal Protocol / `libsignal`
- **Official Warning**: Signal publishes protocol specifications and `libsignal`. However, official Signal documentation explicitly states that **use outside Signal apps is unsupported**.
- **Operational Risk**: APIs, Rust bindings, and bridge interfaces may undergo breaking changes without notice.
- **Decision Rule**: `libsignal` MUST NOT be selected solely due to brand recognition. Direct adoption requires thorough legal, API stability, mobile bridge, and long-term maintenance evaluation.

### B. IETF Messaging Layer Security (MLS - RFC 9420 / RFC 9750)
- **Standardization**: Standardized in RFC 9420 (Core Protocol) and RFC 9750 (Architecture).
- **Scope Limitation**: MLS is primarily a **group key-establishment protocol**. It does NOT by itself define device identity, local storage, backup, push notifications, or abuse prevention.
- **Decision Rule**: An MLS implementation must still be independently evaluated for audit status, maintainer activity, Flutter FFI bindings, and safe local state persistence.

*Note: Signal Protocol and MLS are NOT mutually exclusive and may be combined (e.g., Signal for 1:1 pairwise messaging, MLS for large group messaging).*
