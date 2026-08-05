# Cryptographic Provider Candidates Evaluation

> **Document Status**: Phase 6 Candidate Assessment

---

## Candidate 1: `libsignal` (Signal Protocol)
- **Primary Use Case**: 1:1 Pairwise messaging (X3DH + Double Ratchet) and small group Sender Keys.
- **Language & Binding**: Rust core with C-FFI / Java / Swift / Dart bindings.
- **Licensing**: AGPL-3.0 (Client/Server dependency implications).
- **Pros**: Industry benchmark for 1:1 E2EE, strong mathematical security proofs, forward secrecy & post-compromise security.
- **Cons & Warnings**: **Unsupported outside Signal application**. No backward compatibility guarantees on FFI bindings. AGPL-3.0 license requires strict legal review.

---

## Candidate 2: OpenMLS (IETF MLS RFC 9420)
- **Primary Use Case**: Dynamic multi-party group key establishment and messaging (TreeKEM).
- **Language & Binding**: Rust core (`openmls`), standard C-FFI wrappers available.
- **Licensing**: MIT License.
- **Pros**: Open IETF standard, scalable to large groups $O(\log N)$ rekeying, permissive MIT license.
- **Cons**: Newer ecosystem, fewer production mobile deployments, requires delivery service coordination for epoch messages.

---

## Candidate 3: `libsodium` / Custom Double Ratchet Wrapper
- **Primary Use Case**: Pairwise Double Ratchet implementation over standard primitives (Curve25519, Ed25519, AES-256-GCM, HMAC-SHA256).
- **Language & Binding**: C library (`libsodium`), official Dart bindings (`flutter_libsodium` / `sodium_libs`).
- **Licensing**: ISC License.
- **Pros**: Extremely mature, audited primitives, highly stable APIs, permissive ISC license.
- **Cons**: Requires building and auditing the Double Ratchet state machine wrapper (increased custom code risk).
