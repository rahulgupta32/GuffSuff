# Cryptographic Provider Candidates Evaluation

> **Document Status**: Phase 6 Candidate Assessment (Updated Post-Correction)

---

## Candidate 1: `libsignal` (Signal Protocol)
- **Primary Use Case**: 1:1 Pairwise messaging (X3DH / Double Ratchet) and small group Sender Keys.
- **Language & Binding**: Rust core (`libsignal-protocol-rs`) with C-FFI / Java / Swift / Dart bindings.
- **Licensing**: AGPL-3.0 (Client/Server dependency implications).
- **Unsupported-Use Warning**: **Official Signal documentation explicitly states that use outside Signal apps is unsupported.** APIs, Rust bindings, and bridge interfaces may undergo breaking changes without notice.
- **Pros**: Industry benchmark for 1:1 E2EE, strong mathematical security proofs, forward secrecy & post-compromise security.
- **Cons & Risks**: Unsupported external use, AGPL-3.0 copyleft compliance risks, mobile App Store distribution considerations.

---

## Candidate 2: OpenMLS (IETF MLS RFC 9420)
- **Primary Use Case**: Dynamic multi-party group key establishment and messaging (TreeKEM).
- **Language & Binding**: Rust core (`openmls`), standard C-FFI wrappers available.
- **Licensing**: MIT License.
- **Characterization Scope**: OpenMLS is a **Rust implementation of MLS (RFC 9420)** for group key-establishment. It is a building block for E2EE messaging, but **does NOT itself provide the complete GuffSuff identity, transport, push, backup, recovery, abuse, or product architecture**. It requires application-controlled credential and identity integration, state persistence, and transaction design.
- **Pros**: Open IETF standard, scalable to large groups $O(\log N)$ rekeying, permissive MIT license.
- **Cons**: Requires custom identity binding, delivery service coordination for epoch messages, and Dart/mobile bridge evaluation.

---

## Classification: `libsodium` (Supporting Cryptographic Primitives Library)
- **Classification**: **Supporting cryptographic primitive library — NOT eligible as the primary messaging protocol provider.**
- **Policy Constraint**: `libsodium` is a library of low-level primitives (Ed25519, Curve25519, ChaCha20-Poly1305, AES-GCM). It is NOT an implementation of Signal Protocol, Double Ratchet, X3DH, PQXDH, Sesame, MLS, or a complete secure-messaging protocol.
- **Usage Rule**: **It MUST NOT be used to construct a custom GuffSuff ratchet or key-establishment protocol.** It may be evaluated only if an independently reviewed protocol implementation uses it internally or for a narrowly defined, standards-based supporting function approved by cryptographic review.
