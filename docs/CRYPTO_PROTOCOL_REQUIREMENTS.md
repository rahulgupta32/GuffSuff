# Cryptographic Protocol Requirements Specification

> **Document Status**: Phase 6 Requirements Baseline

---

## 1. Independent Evaluation Matrix: Direct vs Group Messaging

To avoid forcing a single provider to satisfy all architectural requirements, direct messaging (1:1) and multi-party group messaging are evaluated independently.

| Functional / Security Requirement | Direct 1:1 Messaging Requirement | Multi-Party Group Messaging Requirement |
| :--- | :--- | :--- |
| **A. Asynchronous Session Establishment** | Extended Triple Diffie-Hellman (X3DH / PQX3DH) prekey bundle exchange. | KeyPackage distribution via delivery service / key server. |
| **B. Multi-Device Session Management** | Pairwise sessions per active recipient device. | Per-device member insertion into group TreeKEM epoch. |
| **C. Per-Message Key Evolution** | Symmetric + DH Double Ratchet per message step (FS + PCS). | Per-epoch TreeKEM update + Application Secret ratchet. |
| **D. Device Verification** | Cryptographic identity key fingerprint / QR safety number. | Group credential verification + member identity binding. |
| **E. Key-Change Warning** | Untrusted identity key replacement alert (`untrusted_key_change_event`). | Member key update notification across group epoch. |
| **F. Group Key Agreement** | N/A (Pairwise) | TreeKEM epoch update (MLS RFC 9420) or Sender Keys. |
| **G. Group Membership Changes** | N/A | Immediate Add/Remove commit enforcing backward & forward secrecy. |
| **H. Attachment-Key Wrapping** | Out-of-band AES-256-GCM media key inside 1:1 envelope payload. | Out-of-band media key encrypted under current group epoch key. |
| **I. Protocol Versioning** | Envelope header `protocolVersion: 2` with strict fail-closed enforcement. | MLS ciphersuite versioning (`MLS_10_AES128GCM_SHA256_P256` etc.). |
| **J. Migration & Fallback** | Seamless Phase 5 -> Phase 6 upgrade; zero protocol downgrade permitted. | Group epoch migration from legacy to MLS without payload leaks. |
