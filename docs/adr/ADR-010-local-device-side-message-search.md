# ADR-010: Local Device-Side Message Search

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

Because message content is end-to-end encrypted, the backend server possesses zero plaintext message content and cannot perform server-side full-text search.

---

## Decision

Full-text message search is executed **strictly on the user's mobile device** over the local decrypted SQLite database using SQLite FTS5 (Full-Text Search engine).

### Implementation Details
- Local message indexing occurs asynchronously on device as messages are decrypted and stored in Drift.
- FTS5 tables are created inside the encrypted SQLite database on device.
- Devanagari text tokenizer settings configured for accurate Nepali word boundary matching.

---

## Security & Privacy Impact
- 100% privacy preservation: Server cannot be subpoenaed or compromised for search indexes because search index exists only on device.
