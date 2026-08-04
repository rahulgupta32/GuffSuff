# GuffSuff Realtime Protocol Specification

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Protocol Overview

Realtime message routing is established over secure WebSockets (`wss://realtime.guffsuff.com/v1/ws`).

### Message Transport Frame

```json
{
  "type": "MESSAGE_DELIVERY",
  "envelopeId": "018e3a2b-7c91-7890-a123-456789abcdef",
  "senderDeviceId": "device_abc123",
  "recipientDeviceId": "device_xyz789",
  "ciphertext": "base64_encoded_opaque_payload",
  "serverTimestamp": "2026-08-05T05:08:00Z"
}
```

### Connection State Machine
- `CONNECTING` -> `AUTHENTICATED` -> `READY`
- Heartbeat ping/pong interval: 30s.
- Reconnection backoff: Exponential with randomized jitter.
