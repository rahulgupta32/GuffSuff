# GuffSuff Opaque Message Transport Architecture

> **Document Status**: Phase 5 Baseline Architecture  
> **Rule**: Message content MUST remain an opaque encrypted envelope placeholder until Phase 6 Signal Protocol E2EE integration.

---

## 1. System Overview

GuffSuff Phase 5 delivers a reliable, privacy-preserving messaging transport layer. The architecture routes and persists opaque encrypted envelope payloads without inspecting or decrypting message content.

- **API Service**: Manages conversation authorization, envelope submission, idempotency checks, and delivery queries.
- **Realtime Gateway**: Performs WebSocket authentication, event routing (`server.message.delivery`), and receives real-time delivery/read acknowledgements.
- **Worker Queue**: Handles offline delivery retries, envelope expiration enforcement, and opaque background wake-up notifications.
- **PostgreSQL**: Primary durable system of record for conversations, envelopes, device delivery states, and idempotency records.
- **Redis**: Ephemeral WebSocket socket routing and short-lived connection coordination.

---

## 2. Invariants & Security Boundaries

1. **Payload Opacity**: Payloads are treated strictly as binary blobs (`BYTEA` / Base64).
2. **Zero Plaintext Server Storage**: The server never sees or stores message bodies, captions, attachment keys, or previews.
3. **No Fake E2EE Claims**: Mobile UI displays prominent warning banner: `Message transport test mode — production end-to-end encryption is not yet implemented.`
4. **IDOR & Membership Controls**: All envelope submissions, pending queries, and acknowledgements enforce strict direct conversation membership verification.
