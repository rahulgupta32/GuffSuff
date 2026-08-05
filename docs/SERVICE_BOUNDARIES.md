# GuffSuff Service Boundaries & Responsibility Matrix

> **Document Status**: Complete (Phase 1 Specification)

---

## 1. Responsibilities & Prohibitions Matrix

```text
+-----------------------------------------------------------------------------------+
| SERVICE           | ALLOWED RESPONSIBILITIES        | PROHIBITED RESPONSIBILITIES |
+-------------------+---------------------------------+-----------------------------+
| services/api      | • Auth, OTP, Profile management | • Decrypting user message   |
|                   | • Key bundle publishing         |   content or media blobs.   |
|                   | • S3 presigned upload auth      | • Storing private keys.     |
|                   | • Privacy settings & reporting  | • Sending plaintext preview |
|                   | • OpenAPI REST handling         |   notification payloads.    |
+-------------------+---------------------------------+-----------------------------+
| services/realtime | • Authenticated WebSocket state | • Direct database persistence|
|                   | • Encrypted envelope routing    |   for long-term messages.   |
|                   | • Online presence & typing      | • Bypassing user session    |
|                   | • Delivery receipts & ACKs      |   authentication context.   |
|                   | • Redis PubSub fan-out          | • Inspecting E2EE payload.  |
+-------------------+---------------------------------+-----------------------------+
| services/worker   | • Delayed FCM/APNs push queue   | • Bypassing data retention  |
|                   | • Media thumbnail cleanup       |   schedules.                |
|                   | • Scheduled data export jobs    | • Accessing private message |
|                   | • Account deletion workflows    |   decryption keys.          |
+-------------------+---------------------------------+-----------------------------+
| apps/admin        | • User report triage UI         | • Displaying user message   |
|                   | • Account restriction actions   |   plaintext or audio files. |
|                   | • Aggregated service health     | • Unrestricted direct DB    |
|                   | • Immutable audit log view      |   SQL console execution.    |
+-------------------+---------------------------------+-----------------------------+
| apps/mobile       | • Local E2EE key generation     | • Transmitting plaintext    |
|                   | • Payload encryption/decryption |   private keys to server.   |
|                   | • Local SQLite message store    | • Unencrypted media upload. |
|                   | • Offline queue management      |                             |
+-----------------------------------------------------------------------------------+
```

---

## 2. Interface Contracts

- **`services/api` $\leftrightarrow$ `services/realtime`**: Share Redis PubSub event channels and shared Zod/DTO contracts from `packages/contracts`.
- **`services/api` $\leftrightarrow$ `services/worker`**: Shared BullMQ job definitions in `packages/contracts`.
