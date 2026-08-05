# GuffSuff Versioned Message Envelope Specification

> **Document Status**: Phase 5 Envelope Schema Standard

---

## 1. Envelope Structure

The server-visible envelope contains strictly non-sensitive routing metadata and binary payload bytes:

```typescript
export interface MessageEnvelope {
  id: string; // UUIDv7
  clientIdempotencyKey: string; // Cryptographically random UUIDv7/256-bit string
  conversationId: string; // UUIDv7 direct conversation
  senderUserId: string; // UUIDv7
  senderDeviceId: string; // UUIDv7
  recipientUserId: string; // UUIDv7
  protocolVersion: number; // Current = 1
  payloadByteLength: number; // Max 65,536 bytes (64KB)
  opaquePayloadBase64: string; // Base64 encoded opaque payload bytes
  clientCreatedAt: string; // ISO-8601 UTC timestamp
  serverAcceptedAt: string; // ISO-8601 UTC timestamp
  expiresAt: string; // ISO-8601 UTC timestamp
}
```

---

## 2. Payload Rules & Terminology

1. **Terminology**: Payloads in Phase 5 are referred to as `opaque payload`, `envelope payload`, `transport test payload`, or `encrypted-envelope placeholder`. Phase 5 envelopes are NOT end-to-end encrypted.
2. **Digest Scope**: SHA-256 payload digests in `message_idempotency_keys` are used solely for deterministic payload comparison, changed-payload reuse detection, and idempotency conflict detection. SHA-256 does NOT provide encryption, confidentiality, sender authentication, or recipient authentication.
3. **Maximum payload size**: 64KB (65,536 bytes raw, ~87,382 Base64 characters).
4. **Unknown protocol versions**: Rejected unless explicit backwards compatibility rules exist.
5. **Prohibited fields**: Plaintext body, plaintext caption, attachment key, private key, plaintext reply excerpt, reaction label, edit text, or notification preview.
