# GuffSuff Session Security & Token Management Specification

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Raw refresh tokens MUST NOT be stored in backend databases. Storage uses SHA-256 token hashes (`SEC-SESSION-001`).

---

## 1. Token Lifecycles & Constraints

- **Access Token (JWT)**: Ephemeral lifetime of **15 minutes** (900 seconds). Contains `sub` (userId), `deviceId`, `iss` (`guffsuff-api`), `aud` (`guffsuff-mobile`), and `exp`. Signed via RS256 / EdDSA.
- **Refresh Token**: Lifetime of **30 days**. Issued as cryptographically secure 256-bit random string (`opaque_refresh_token`). Backend stores `SHA-256(opaque_refresh_token)` in `sessions` table.
- **Refresh Token Rotation**: Every call to `/api/v1/auth/refresh` invalidates the old refresh token and issues a new refresh token pair.
- **Reuse Detection**: If a previously consumed refresh token is presented, the server flags a potential replay attack, revokes all active session tokens for that device family, and logs security event `EVT_TOKEN_REUSE_DETECTED`.

---

## 2. Session Binding & Revocation Controls

1. **Per-Device Session Binding**: Sessions are bound strictly to `(userId, deviceId)`. A user can maintain up to 5 concurrent registered device sessions.
2. **Server-Side Revocation**: Invoking `POST /api/v1/devices/:id/revoke` immediately invalidates the target device's refresh token and pushes a socket disconnect event.
3. **High-Risk Action Re-Authentication**: Sensitive actions (changing PIN, linking new device, requesting account deletion) require re-authenticating via OTP or registration PIN.
4. **Admin Web Session Security**: `apps/admin` sessions enforce HTTP-only, SameSite=Strict, Secure cookies with 15-minute inactivity timeouts and mandatory MFA challenges.
