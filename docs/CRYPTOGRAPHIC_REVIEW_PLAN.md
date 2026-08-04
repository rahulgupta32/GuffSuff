# GuffSuff Cryptographic Review & Audit Plan

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Independent third-party cryptographic review is mandatory prior to MVP production launch.

---

## 1. Cryptographic Review Scope

1. **`packages/crypto-adapter` Interface Compliance**: Verification that no application feature code bypasses the abstraction boundary.
2. **Double Ratchet & Prekey State Machine**: Verification of forward secrecy (FS), post-compromise security (PCS), and prekey depletion handling.
3. **Encrypted Media Ciphertext**: Verification of AES-256-GCM attachment encryption, IV uniqueness, and MAC verification.
4. **Group Key Distribution**: Verification of group membership epoch transitions and member removal key rotation.
5. **Mobile Secure Enclave Integration**: Verification of hardware-backed key storage on Android Keystore and iOS Keychain.

---

## 2. Review Methodology & Test Vectors

- **Known-Answer Tests (KAT)**: Execution of official test vectors supplied by the selected cryptographic protocol library (Signal Protocol / OpenMLS).
- **Ciphertext Malleability & Replay Testing**: Verification that tampered ciphertext or replayed envelopes fail decryption cleanly without throwing unhandled exceptions.
