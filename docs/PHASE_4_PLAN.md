# Phase 4 — Secure Identity, Registration, Profile, Session, and Device Management Plan

This document defines the complete scope, architecture, database schemas, security requirements, and acceptance criteria for Phase 4 of GuffSuff.

---

## Approved Initial Product Decisions

1. **OTP Expiration**: 5 minutes (300 seconds).
2. **OTP Resend Cooldown**: Progressive step-up: 60s, then 120s, then 300s.
3. **Username Format**: 3–20 lowercase ASCII letters, numbers, and underscore (`^[a-z0-9_]+$`).
4. **Username Change Cooldown**: 30 days.
5. **Display Name Length**: 2–50 Unicode grapheme clusters.
6. **Access Token Lifetime**: 15 minutes.
7. **Refresh Token Lifetime**: 30 days.
8. **Maximum Active Devices**: 5 concurrent active sessions per account.
9. **Phone-Number Visibility**: Nobody.
10. **Phone Discoverability**: Disabled.
11. **Last Seen Visibility**: Contacts Only.
12. **Online Status Visibility**: Same as last seen (Contacts Only).
13. **Profile Photo Visibility**: Contacts Only (Effective behavior in Phase 4: Nobody).
14. **Read Receipts**: Enabled and user-configurable.
15. **Security Notifications**: Enabled.
16. **Default Country**: Nepal (`+977`). International numbers accepted via E.164, launch availability configurable (`ENABLE_INTERNATIONAL_SMS_REGISTRATION`).

---

## Technical & Security Corrections Applied

1. **Phone Number Encryption & Blind Indexing**:
   - Phone numbers are stored encrypted using AES-256-GCM (`phone_encrypted`).
   - Lookups and uniqueness use a keyed HMAC-SHA256 blind index (`phone_blind_index` = HMAC(E164, PEPPER)). Plaintext E.164 is never stored in database tables or operational logs.

2. **Versioned Keyed OTP Verifier**:
   - OTP verifier: `HMAC-SHA256(challenge_id + ":" + otp_code, SERVER_PEPPER_V1)`.
   - Verified via `crypto.timingSafeEqual` in constant time.
   - Attempt count incremented atomically in SQL.

3. **Development OTP Simulator Build Isolation**:
   - Isolated at package and build-entry-point level (`@guffsuff/otp-simulator`).
   - Impossible to bundle or initialize in staging and production builds.

4. **Explicit Refresh Token Family and Token Instance Rotation**:
   - `refresh_token_families`: Tracks family status (`is_compromised`).
   - `refresh_tokens`: Instance records (`id`, `family_id`, `token_verifier_hash`, `parent_token_id`, `replacement_token_id`, `expires_at`, `is_rotated`, `rotated_at`, `is_revoked`).
   - Supports atomic rotation with a 10-second grace window for concurrent requests.
   - Reuse of rotated token revokes entire family, invalidates all sessions, and emits high-severity security event.

5. **Access Token Revocation & Session Versioning**:
   - Access tokens contain `session_id`, `user_id`, `device_id`, and `session_version`.
   - Access token secrets are never stored. API Gateway / Auth Guard checks session status and `session_version` against Redis / PostgreSQL authoritatively.

6. **Layered OTP Abuse Controls**:
   - Limits separated by Phone Blind Index, Challenge ID, Installation ID, IP, ASN/Risk category, and Provider Cost.
   - Shared IP addresses receive separate velocity windows.

7. **Registration-Lock PIN Security**:
   - 6 to 12 digit PIN (8 recommended).
   - Hashed using Argon2id + server-side pepper with versioned parameters.
   - Atomic attempt tracking (`registration_lock_attempts`) with lockout window.
   - Disabling/modifying PIN requires recent re-authentication and current PIN.

8. **Expanded Audit Events & Isolated Security Events**:
   - `audit_events`: `actor_type`, `actor_id`, `action`, `target_type`, `target_id`, `reason`, `correlation_id`, `request_id`, `outcome`, `before_state_json`, `after_state_json`.
   - `security_events`: Internal metadata is stripped from API projections to ensure internal abuse signals are inaccessible from client apps.

---

## Out of Scope for Phase 4

- Direct messaging, group messaging, message envelopes, message storage.
- Contact discovery.
- Attachments, media upload.
- Production cryptography / Signal Protocol / MLS.
- Voice/video calls, payments, public deployment.
