# ADR-010: Local Device-Side Message Search & Persistence Security

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Privacy Architect, GuffSuff Lead Architecture Team
- **Decision Status**: Proposed

---

## Context

Because message content is end-to-end encrypted, the backend server possesses zero plaintext message content and cannot perform server-side full-text search. Message search must occur locally on the user's mobile device.

---

## Decision

Full-text message search is executed **strictly on the user's mobile device** over the local decrypted SQLite database using SQLite FTS5 (Full-Text Search engine).

### Implementation & Database Security Clarification
1. **Persistence & Query Abstraction**: `drift` provides Dart ORM persistence and FTS5 query abstractions. **Drift itself does not provide database encryption.**
2. **At-Rest Encryption**: At-rest encryption requires a separately evaluated SQLCipher-compatible SQLite implementation or another approved encrypted database.
3. **Key Source**: Encryption keys MUST be generated and stored in platform hardware-backed secure storage (Android Keystore / iOS Keychain).
4. **Devanagari Tokenization**: FTS5 tables configured with custom Devanagari word boundary tokenizers for accurate Nepali search matching.

---

## Security Review Requirements
- Database key recovery, key rotation, multi-device backup exclusion, memory exposure during active query execution, and rooted/jailbroken device limitations remain subject to Phase 2 security review.
