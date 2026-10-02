# गफसफ production readiness — 2026-10-02

Status: IN DEVELOPMENT. Public launch is blocked.

## Implemented in this change

- Registration requires validated phone and device metadata, binds the submitted phone to the verified challenge, rejects expired/consumed challenges, and consumes challenges in the account transaction.
- OTP verification uses one checked-out database connection and transaction for row locking and attempt updates.
- Refresh families reference persisted sessions. Rotation rejects revoked/expired sessions and devices, inserts the successor before the foreign-key update, and preserves the session ID/version in access tokens.
- Refresh-token reuse fails closed and revokes the family and device sessions. Clients must serialize refresh calls; the old simulated grace tests were removed.
- Legacy refresh families without session binding are revoked by migration 004, requiring reauthentication.
- Production/staging reject missing, short, or known development identity secrets.
- REST authorization checks session expiry; transport controllers use the guard's userId field.
- Visible brand strings and the Android launcher label use गफसफ.

## Verification

Frozen-lockfile dependency installation succeeded. API and its dependencies build and typecheck; the initial lint run passed. API test suite: 43 passed, 0 failed, including actual service regression tests using controlled database doubles.

These tests do not establish PostgreSQL concurrency behavior or migration compatibility. PostgreSQL/Docker and Flutter are not installed in this execution environment. Flutter tests, Android builds and real-device testing were not run.

## Ten-person beta

The owner supplied ten proposed Nepal phone numbers. Do not commit their numbers to this public repository, seed production accounts, or substitute a shared OTP. Each tester should register with their own delivered OTP. Use anonymous T01–T10 labels in issue reports; keep the mapping in private operations storage.

Test all 45 unordered tester pairs, then selected groups. Include offline/reconnect, force-stop/restart, background delivery, duplicated sends, expired OTP, resend limits, device revocation, refresh replay, Nepali text, low bandwidth and low-end Android devices. Record signed build ID and server version for every run. No messages or accounts were created for the proposed testers by this change.

## Remaining launch blockers

1. Mobile phone-entry, OTP and profile screens still need complete API wiring, challenge propagation, token storage/refresh, returning-user authentication and route protection.
2. Production SMS provider implementation and credentials; delivery failures, quotas and abuse controls.
3. Supported E2EE provider, key lifecycle, encrypted local database and real two-device secure transport.
4. Replace demo repositories and hardcoded conversation bubbles throughout the application.
5. Actual FCM/APNs integration, backend token registration and worker delivery.
6. Contacts, groups, encrypted media/voice notes, message operations and privacy controls from the existing MVP scope.
7. Operational admin authentication/RBAC, reporting/blocking, deletion/export and retention enforcement.
8. Production HTTPS configuration, signing keys, staging deployment, restore tests, monitoring, load tests and independent security review.
9. PostgreSQL migration/concurrency regression testing, Flutter validation and green CI on the final release commit.

No production deployment or store release is authorized by this document. Do not describe UI prototypes, boundary binaries, or passing unit tests as a production-ready messenger.
