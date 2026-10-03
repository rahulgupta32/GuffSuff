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

The first increment did not establish PostgreSQL concurrency behavior or migration compatibility, or run Flutter/Android checks. The later mobile verification record below supersedes its Flutter limitation. PostgreSQL migration/concurrency tests, signed Android/iOS builds and real-device testing remain outstanding.

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

## 2026-10-03 mobile onboarding increment

- Removed the fixed-code OTP simulator from mobile authentication. The UI requests a real challenge, submits `otpCode` to `/api/v1/auth/otp/verify`, and carries that exact challenge into registration.
- Registration submits required phone/device metadata, collects consent, and stores the returned session as a single secure-storage record.
- Startup restores the saved session through server-side refresh. Refresh requests are serialized. Logout clears local authentication even if the server is offline.
- Signed-out routes redirect to onboarding. Registration screens require an appropriate challenge. Release builds default to production and require an HTTPS API origin.
- Chats/devices/profile use authenticated API requests; contact discovery remains unavailable. Demo records and fixed message bubbles are no longer used in the active screens.
- Mobile CI now checks formatting and reports Android/iOS build failures.

Still incomplete: returning-user OTP login/recovery, actual SMS delivery, production legal documents and links, complete localization of new error/consent text, contact discovery, device action wiring, E2EE and push. Registration cannot be advertised as a complete production authentication system until these and real-device checks pass.

### Mobile verification record

Flutter 3.29.2 was installed and used in CI mode, which avoids its Azure metadata auto-detection. Its archive extraction used `--no-same-owner` for this container. The mobile lockfile was regenerated against this pinned SDK because the previous lockfile required Flutter >=3.38.4 / Dart >=3.11, incompatible with the CI baseline.

- `flutter analyze`: no issues.
- `flutter test`: 35 passed, 0 failed.
- Dart format check: 37 files, no changes.
- API tests repeated: 43 passed, 0 failed.
- Diff whitespace check: passed.

HTTP tests use controlled responses and storage doubles. They do not prove SMS delivery, backend registration against PostgreSQL, real hardware keystore behavior, signed store builds or working E2EE. Existing simulated push/transport tests remain development tests. The generic simulated notification now excludes sender names as well as message contents.

## Returning-user login and SMS adapter increment

- `/api/v1/auth/login` distinguishes new registration from returning accounts only after phone verification. It checks challenge binding/expiry/consumption, account status, PIN requirements/lockout, and device revocation.
- Successful login creates or reuses the installation's device and consumes its challenge in the same transaction as token issuance. Account registration now also issues its session in the account transaction.
- Mobile OTP verification attempts login before profile setup. PIN errors can be retried without repeating an already completed OTP verification. New users proceed to profile setup; existing users store the server session and enter chats.
- Registration-lock pepper now rejects unsafe production defaults.
- Optional Twilio SMS adapter, failure handling and unknown-cost migration 005 are implemented. It remains unconfigured and has made no live requests. See SMS_PROVIDER_SETUP.md.

Forgotten-PIN recovery, delivery receipt processing, billing reconciliation and distributed abuse controls remain incomplete. Earlier references to missing returning-user login/production SMS implementation are superseded by this increment; real SMS operation remains unverified until an approved provider account is configured.

Validation for this increment: 55 API tests and 38 mobile tests passed; API/dependency build, typecheck and lint passed; Flutter analysis reported no issues; Dart formatting and diff whitespace checks passed. SMS tests use a fake HTTP request; login tests use controlled database doubles. PostgreSQL runtime/migrations, SMS carrier delivery and signed real-device builds remain unverified.

## Transport authorization and receipt increment — 2026-10-03

- Pending-envelope requests now apply the conversation in the URL, active-device ownership and conversation membership instead of returning all conversations for the device.
- Submission checks that the recipient is a different member of the same conversation. Malformed/noncanonical base64 and expired envelopes are rejected. A retried idempotency key cannot silently change its conversation, recipient or protocol.
- Read receipts require the body envelope to match the URL. The service resolves the conversation from the recipient's authorized envelope and active device, then updates receipt and read position in one transaction. The read position advances by server acceptance time and envelope ID; older receipts cannot move it backward.
- Late/repeated delivery receipts preserve read status and the original delivery timestamp. Revoked devices cannot acknowledge delivery.
- Validation: all 30 API/dependency build, typecheck and lint tasks passed; all 66 API tests passed, including 11 new transport regressions. These use query doubles; real PostgreSQL execution and concurrent transaction validation remain required. Mobile code was unchanged in this increment.

Remaining messaging release gates: production encryption provider and per-device keys, real network transport, encrypted local persistence/outbox, recipient-device fan-out, reconnect/offline synchronization, receipt integration in mobile, and physical-device testing. Concurrent first submissions can still race on the idempotency unique constraint; concurrent conversation creation also needs conflict-safe handling. Delivery acknowledgement audit rows are not yet deduplicated. Pending fetches need bounded pagination and expiry/retention limits must be enforced server-side. The existing native/test crypto provider and simulated connection lifecycle remain unsuitable for release.
