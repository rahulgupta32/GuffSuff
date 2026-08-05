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

## 2. Payload Rules

1. Maximum payload size: 64KB (65,536 bytes raw, ~87,382 Base64 characters).
2. Unknown protocol versions are rejected unless explicit backwards compatibility rules exist.
3. Prohibited fields: Plaintext body, plaintext caption, attachment key, private key, plaintext reply excerpt, reaction label, edit text, or notification preview.
