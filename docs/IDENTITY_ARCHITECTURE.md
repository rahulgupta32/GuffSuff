# GuffSuff Identity Architecture & System Specifications

## 1. Overview

GuffSuff Identity Foundation manages user authentication, phone normalization, OTP challenge/verification, account registration, profiles, usernames, rotating sessions, device management, privacy settings, security events, and registration lock PINs.

```mermaid
graph TD
    Client[Flutter Mobile / Client App] -->|HTTPS REST API /v1| API[services/api]
    API -->|Phone Normalization / Crypto| CryptoAdapter[packages/crypto-adapter]
    API -->|Session & Abuse State| Redis[(Redis Cluster)]
    API -->|Durable Persistence| DB[(PostgreSQL)]
    API -->|Security Events / OTP Jobs| Queue[packages/queue]
    Queue -->|Process Background Jobs| Worker[services/worker]
    API -->|Security Event Push| Realtime[services/realtime WebSocket]
```

## 2. Component Boundaries

- `services/api`: Synchronous identity operations, REST controllers, JWT generation/validation, session checks.
- `services/worker`: Asynchronous background jobs for OTP delivery retries, security event notifications, session cleanup.
- `services/realtime`: Realtime WebSocket notifications for device revocation, session revocation, and security alerts.

## 3. Data Protection

- **Phone Numbers**: Encrypted using AES-256-GCM (`phone_encrypted`), searched via HMAC-SHA256 blind index (`phone_blind_index`). Plaintext E.164 is never logged or stored.
- **OTPs**: HMAC-SHA256 verifiers using server pepper. Never stored in plaintext.
- **Refresh Tokens**: Opaque random strings, stored as SHA-256 hashes in `refresh_tokens`.
- **Registration Lock PIN**: Hashed with Argon2id + server pepper (`m=65536, t=3, p=4`).
