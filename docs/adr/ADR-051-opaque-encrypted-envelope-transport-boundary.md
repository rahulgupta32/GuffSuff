# ADR-051: Opaque Encrypted Envelope Transport Boundary

## Context
Phase 5 implements a multi-device messaging transport system for GuffSuff before Signal Protocol E2EE is integrated in Phase 6.

## Decision
1. Backend services handle message payloads strictly as opaque binary blobs (`BYTEA` / Base64).
2. Backend servers are cryptographically incapable of decrypting message payloads.
3. No plaintext message body, reply excerpt, caption, attachment metadata, or notification preview may be persisted or logged server-side.
4. Mobile clients MUST NOT claim production end-to-end encryption until Phase 6 integration passes security release gates.

## Consequences
- Guarantees server-side data opacity.
- Eliminates risk of server-side data leaks or plaintext logging vulnerabilities.
