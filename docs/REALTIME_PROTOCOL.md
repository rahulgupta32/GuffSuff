# GuffSuff Realtime Delivery Protocol

> **Document Status**: Complete (Phase 1 Specification)  
> **Protocol**: WebSockets (`wss://realtime.guffsuff.com/v1/ws`)  
> **Framing**: JSON messages with base64 binary ciphertext placeholders

---

## 1. Connection Lifecycle

### Authentication & Handshake

1. Client connects via WebSocket with query token: `wss://realtime.guffsuff.com/v1/ws?token=<access_token>&deviceId=<device_uuidv7>`
2. Gateway verifies JWT token and device status against Redis session cache.
3. Server emits `CONNECTED` frame:
   ```json
   {
     "type": "CONNECTED",
     "connectionId": "conn_018e3a2b_1234",
     "serverTime": "2026-08-05T05:16:00.000Z",
     "heartbeatIntervalMs": 30000
   }
   ```

### Heartbeat & Reconnection

- **Heartbeat**: Client sends `{"type": "PING"}` every 30 seconds. Server responds `{"type": "PONG"}`.
- **Backoff**: On disconnect, client reconnects using exponential backoff with jitter: $T_{backoff} = \min(60s, 2^n \cdot 1000ms + \text{random}(0, 1000ms))$.

---

## 2. Realtime Event Types

### Message Delivery Frame (Server -> Recipient Device)

```json
{
  "type": "ENVELOPE_DELIVERY",
  "eventId": "018e3b01-8c12-7890-a123-111122223333",
  "conversationId": "018e3a00-1111-2222-3333-444455556666",
  "senderUserId": "018e3a00-0000-0000-0000-000000000001",
  "senderDeviceId": "018e3a00-0000-0000-0000-000000000002",
  "clientCorrelationId": "client_msg_req_998877",
  "encryptedPayload": "BASE64_OPAQUE_E2EE_CIPHERTEXT_NO_PLAINTEXT",
  "serverTimestamp": "2026-08-05T05:16:05.123Z"
}
```

### Delivery Acknowledgement (Recipient Device -> Server)

```json
{
  "type": "ACK_DELIVERY",
  "eventId": "018e3b01-8c12-7890-a123-111122223333",
  "conversationId": "018e3a00-1111-2222-3333-444455556666",
  "recipientDeviceId": "018e3a00-0000-0000-0000-000000000003",
  "timestamp": "2026-08-05T05:16:05.456Z"
}
```

### Ephemeral Events (Typing & Presence)

- **Typing Indicator** (`TYPING_START` / `TYPING_STOP`): Ephemeral message routed directly via Redis PubSub without PostgreSQL persistence.
- **Presence** (`PRESENCE_CHANGE`): Emits online/offline changes based on user privacy settings.
