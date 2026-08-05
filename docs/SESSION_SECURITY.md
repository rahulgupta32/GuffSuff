# GuffSuff Session Security & Token Management Specification

> **Document Status**: Phase 5 Security Architecture Baseline  
> **Rule**: Raw refresh tokens MUST NOT be stored in backend databases. Storage uses SHA-256 token verifier hashes (`SEC-SESSION-001`).

---

## 1. Token Lifecycles & Constraints

- **Access Token (JWT)**: Ephemeral lifetime of **15 minutes** (900 seconds). Contains `sub` (userId), `deviceId`, `iss` (`guffsuff-api`), `aud` (`guffsuff-mobile`), and `exp`.
- **Refresh Token**: Lifetime of **30 days**. Issued as cryptographically secure 256-bit random string (`opaque_refresh_token`). Backend stores `SHA-256(opaque_refresh_token)` in `refresh_tokens` table.
- **Refresh Token Rotation**: Every call to `/api/v1/auth/refresh` invalidates the old refresh token and issues a new refresh token pair.
- **Reuse Detection**: If a previously consumed refresh token is presented outside the 10-second network concurrency window, the server flags a replay attack, immediately revokes all tokens in the family, and emits security event `SEC_EVENT_REFRESH_TOKEN_REUSE`.

---

## 2. Refresh Token Concurrency & Reuse Detection Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor MobileClient as Mobile Client
    participant API as API Gateway (SessionService)
    participant DB as PostgreSQL (refresh_tokens)
    participant Redis as Redis (Revocation Cache)

    Note over MobileClient, API: Case 1: Normal Refresh Rotation
    MobileClient->>API: POST /api/v1/auth/refresh (RefreshToken T1)
    API->>DB: SELECT * FROM refresh_tokens WHERE verifier_hash = SHA256(T1) FOR UPDATE
    DB-->>API: Valid T1 (unconsumed, active family F1)
    API->>DB: UPDATE refresh_tokens SET is_consumed=true, consumed_at=NOW(), replaced_by=T2 WHERE id=T1
    API->>DB: INSERT INTO refresh_tokens (family_id=F1, parent_id=T1, verifier_hash=SHA256(T2))
    API-->>MobileClient: Return new AccessToken JWT + RefreshToken T2

    Note over MobileClient, API: Case 2: Concurrent Retry Window (10s Grace Period)
    MobileClient->>API: Retry POST /api/v1/auth/refresh (RefreshToken T1)
    API->>DB: SELECT * FROM refresh_tokens WHERE verifier_hash = SHA256(T1) FOR UPDATE
    DB-->>API: T1 is consumed, consumed_at < 10s ago, replaced_by=T2
    API-->>MobileClient: Idempotent Return existing T2 (No new branch created)

    Note over MobileClient, API: Case 3: Malicious Reuse (After 10s Window)
    MobileClient->>API: Replay POST /api/v1/auth/refresh (RefreshToken T1 after 10s)
    API->>DB: SELECT * FROM refresh_tokens WHERE verifier_hash = SHA256(T1) FOR UPDATE
    DB-->>API: T1 consumed_at > 10s ago (COMPROMISED FAMILY F1!)
    API->>DB: UPDATE refresh_tokens SET is_revoked=true WHERE family_id=F1
    API->>Redis: SET session:revoked:device_id TTL 30d
    API->>DB: INSERT INTO security_events (event_type="refresh_token_reuse_detected")
    API-->>MobileClient: 401 Unauthorized (Family Revoked)
```

---

## 3. Concurrency Invariants & DB Authority

1. **Single Authoritative Lineage**: A token family `family_id` maintains one primary chain. Branching is prohibited.
2. **10-Second Concurrency Window**: Retries within 10s of rotation return the previously issued child token `replaced_by` rather than creating a new lineage.
3. **Database Transaction Lock**: All token updates execute inside PostgreSQL `BEGIN ... FOR UPDATE ... COMMIT` transactions to eliminate application-level race conditions.
4. **Immediate Invalidation on Revocation**: Device revocation or `logout_all` invalidates all families owned by the target session in DB and Redis.
