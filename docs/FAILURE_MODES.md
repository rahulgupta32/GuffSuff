# GuffSuff Structured Failure Modes & Resilience Analysis

> **Document Status**: Complete (Phase 1 Specification)

---

## Failure Matrix & Recovery Procedures

| Failure Scenario | Expected Behavior | Data-Loss Risk | Client Handling | Server Handling | Retry / Recovery Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **No / Unstable Internet** | Client queues outbound messages in local SQLite; displays subtle offline banner. | Zero data loss. | Local SQLite queueing with state `SENDING_PAUSED`. | Accepts queued envelopes when socket reconnects. | Exponential backoff with jitter on WebSocket reconnect. |
| **Duplicate Realtime Event** | Envelope processed exactly once on device using `client_idempotency_key`. | Zero data loss. | Suppresses duplicate UI render; re-sends ACK. | Deduplicates via Redis idempotency key cache. | Instant ACK return. |
| **Redis Outage** | Rate limits temporarily fall back to DB or pass-through; PubSub falls back to DB polling. | Ephemeral presence data lost. | Retries failed socket connections. | Degrades gracefully; logs critical alert. | Sentinel / Cluster automatic node failover (< 15s). |
| **PostgreSQL Outage** | System switches to read-only or returns 503 for auth/registration actions. | Zero data loss for committed records. | Displays friendly error: "System undergoing maintenance". | Rejects write requests; preserves transaction log integrity. | Automated WAL failover to standby replica (< 30s). |
| **S3 Storage Unavailable** | Media uploads/downloads fail gracefully; text messaging unaffected. | Zero data loss. | Displays "Upload failed, tap to retry". | Returns `503 Service Unavailable` on presigned URL request. | Client retries upload when object store health recovers. |
| **OTP Provider Outage** | OTP requests fail or fall back to secondary SMS provider. | Zero account data loss. | Displays "SMS delayed, please try again shortly". | Triggers failover to secondary SMS gateway vendor. | Automatic provider failover in `services/api`. |
| **Revoked Device Access** | Revoked device rejected on next API call or socket ping. | Zero data loss for user account. | Forces local session logout and clears local crypto keys. | Rejects JWT token with `AUTH_DEVICE_REVOKED` (401). | User must re-register device with OTP. |
| **Device Clock Incorrect** | Server detects severe timestamp drift (> 5 mins skew). | Zero data loss. | Prompt user: "Please adjust device clock setting". | Rejects request with `skew_detected` error. | Sync device clock via NTP. |
