# GuffSuff Logging, Observability & Data Redaction Policy

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Log streams MUST use an allowlist-based schema. Logging of sensitive credentials, keys, tokens, or plaintext message contents is strictly prohibited (`SEC-LOG-001`).

---

## 1. Prohibited Logging Categories (Never Log List)

Application code, proxies, log drainers, crash reporting SDKs, and CI runners MUST NEVER log:

1. **Plaintext Message Contents**: Raw text, reply quotes, reactions, or draft text.
2. **Decrypted Media Attachments**: File contents, image thumbnails, or EXIF metadata.
3. **OTP Values**: Raw 6-digit OTP codes or unhashed OTP verification payloads.
4. **Session Tokens & Credentials**: Access JWTs, refresh tokens, bearer headers, or registration PINs.
5. **Private Cryptographic Keys**: Identity private keys, signed prekey private keys, or one-time prekey private keys.
6. **S3 Attachment Keys & Master Keys**: $K_{media}$ keys, IVs, or MAC hashes.
7. **Database Encryption Keys**: SQLCipher passphrase strings or platform Keystore/Keychain master keys.
8. **Unmasked Phone Numbers**: Complete raw E.164 phone numbers (MUST mask e.g. `+97798****567`).
9. **Push Tokens**: Raw FCM registration tokens or APNs device tokens.
10. **Full Contact Books**: Array of user contacts or uploaded address book hashes.
11. **User Report Evidence**: Decrypted evidence text or attached report files in standard app logs.

---

## 2. Safe Logging Allowlist Representations

| Category | Unsafe Field | Approved Safe Representation |
| :--- | :--- | :--- |
| **Request Tracking** | User IP / Full URL | `requestId` (UUIDv7 correlation ID), HTTP method, route template (e.g. `/api/v1/auth/otp/verify`). |
| **User Identity** | Phone number / Email | Pseudonymous `userId` (UUIDv7) or masked phone (`+97798****567`). |
| **Session Authentication** | `Authorization: Bearer <jwt>` | SHA-256 fingerprint of JWT header (`tokenFingerprint: "a1b2c3..."`). |
| **Realtime Envelope** | `encryptedPayload` Base64 | `envelopeId`, `conversationId`, `senderDeviceId`, payload size in bytes. |
| **S3 Media File** | File name / $K_{media}$ key | Opaque `objectKey` UUID, MIME category (`image/*`), binary size bytes. |
| **Error Handling** | Raw SQL error with values | Generic `errorClass` (e.g. `QueryFailedError`), internal error code (`DB_CONSTRAINT_VIOLATION`). |

---

## 3. Automated Redaction Verification Tests

Automated CI integration tests MUST verify that sensitive fields are not emitted by:
- API service console logs (`services/api`).
- Realtime gateway logs (`services/realtime`).
- Worker background process logs (`services/worker`).
- Mobile application debug logs (`apps/mobile`).
- Admin web console server logs (`apps/admin`).
- NGINX / Cloudflare reverse proxy access logs.
- OpenTelemetry tracing spans & Prometheus metrics labels.
- Crashlytics / Sentry crash reporting payloads.
- GitHub Actions CI runner step outputs.
