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

## Retry and conversation creation increment — 2026-10-03

- Envelope submission now begins a single transaction before device authorization and locks the sender device row through idempotency lookup, envelope/device insertions and commit. Competing submissions for the same device serialize, so a matching retry can return the committed envelope instead of racing on the unique retry key. Failures roll back and release the client. This serializes all submissions per sender device and should be load-tested.
- An existing matching envelope remains an idempotent success after its expiry; expiry validation applies to new submissions.
- Direct conversation creation uses INSERT ON CONFLICT DO NOTHING followed by a fresh transaction query for the persisted participant pair. Memberships use that persisted ID and conflict-safe insertion. Fixed an existing six-values/five-placeholders bug in the membership insert.
- Validation: 71 API tests passed; all 30 API/dependency build, typecheck and lint tasks passed; diff checks passed. Five new tests cover cached transaction commits, post-expiry retries, rollback/release, and new/competing conversation creation. Query doubles verify control flow and SQL arguments; they do not establish actual PostgreSQL lock behavior under concurrency. No mobile changes or live messaging/SMS testing in this increment.
- Supersedes the previous note that first envelope submissions and direct-conversation creation have unhandled unique-constraint races. Real PostgreSQL concurrent tests remain a release gate. Production encryption, network transport, offline sync, bounded pending fetches and deduplicated delivery audit rows remain incomplete.

## Mobile HTTP envelope client increment — 2026-10-03

- Added EnvelopeApi for authenticated direct-conversation creation, opaque ciphertext submission, conversation-scoped pending fetches, delivery/read acknowledgement and status retrieval. It uses actual REST routes rather than the simulated TransportService connection lifecycle.
- AuthSession now shares authenticated GET/POST handling, accepts successful 2xx responses, and retries once after refresh while preserving the caller's retry payload. A session-change guard prevents returning a late response or retrying under a different session after logout.
- Submission checks identifiers, ciphertext byte values/size, retry-key length and positive protocol version. The caller must persist the original retry key and ciphertext; this client does not invent keys or perform encryption. Downloads do not auto-acknowledge: receipt calls are explicit so the future coordinator can store ciphertext durably before delivery acknowledgement.
- This is a transport client only. The conversation composer remains disabled because production cryptography, per-device key distribution, encrypted local persistence/outbox, and the coordinating send/receive lifecycle are not implemented. Real carrier/SMS, PostgreSQL concurrency and physical-device testing remain outstanding.
- Validation for the mobile HTTP client: all 45 Flutter tests passed (seven new transport/session regressions); Flutter analysis reported no issues after fixing three style diagnostics; Dart formatting and diff checks passed. Dependencies were restored in the reset environment without changing pubspec.lock. These tests use HTTP doubles, not real phones or a deployed API.

## Ciphertext journal increment — 2026-10-03

- Added MessageJournal backed by the platform secure-storage adapter, with separate account/device scopes and serialized operations within one owner instance. It persists ciphertext and transport metadata, not plaintext message text.
- Outbox entries preserve their original retry key, ciphertext and timestamps until server acceptance and successful local removal. Offline errors and failed local removal retain the persisted entry for another idempotent attempt.
- Incoming ciphertext is validated and persisted before delivery acknowledgement. Duplicate downloads retry receipts without duplicating storage; conflicting ciphertext under the same envelope ID is rejected. PostgreSQL base64 line wrapping is normalized. Sender/protocol/timing metadata is retained for later crypto integration.
- Queue operations check the authenticated account/device before transport actions. Corrupt journals fail closed; capacity errors prevent acknowledgement rather than silently discarding ciphertext. Storage has an explicit default 256 KiB bound shared by inbox/outbox.
- Validation: 55 Flutter tests passed, including ten new journal regressions; Flutter analysis reported no issues; Dart formatting and diff checks passed. Tests use storage/API doubles and reconstructed instances, not hardware secure storage, real process crashes or deployed services. Backend unchanged.
- This is a bounded transport journal foundation, not a complete chat-history database. Exactly one instance must own each scope; cross-instance/process coordination, inbox pruning/export, richer local persistence, background reconnect scheduling and UI integration remain outstanding. Platform storage capacity/performance and crash durability need physical-device validation before enabling this in release. Crypto state and journal state are not yet committed atomically because the production encryption provider is still missing. The composer remains disabled; no messages or SMS were sent.

## Server receipt recovery and bounded synchronization — 2026-10-04

- Pending-envelope downloads now return at most 100 records, ordered by server acceptance time then envelope ID. The existing array response remains compatible with EnvelopeApi. After successful storage and acknowledgements, subsequent fetches retrieve the next pending batch; the coordinator still needs to schedule those fetches.
- Delivery authorization, row locking, status update and audit insertion now share one transaction. Membership and active-device ownership are checked before writes. Late delivery receipts preserve read state and original delivery time.
- Added migration 006_receipt_idempotency.sql. It keeps the earliest existing acknowledgement per envelope/device/type, removes later duplicates, and installs a unique index under a transaction and write-blocking table lock. Apply before deploying the new ON CONFLICT receipt code. On large installations this migration requires a maintenance window; it has not been run against a live database here.
- Read receipts now also write their audit row. Both delivery and read inserts use the unique receipt key to tolerate repeats without duplicate audit history.
- Validation: all 75 API tests passed, including four new receipt/batch regressions; all 30 API/dependency build, typecheck and lint tasks passed; diff checks passed. Query doubles validate service flow and SQL construction, not actual PostgreSQL concurrency, migration cleanup, or deployed performance. Mobile unchanged; its previous 55-test result was not rerun in this increment.
- Remaining: background synchronization coordinator, production cryptography, atomic crypto/local-state commits, scalable local database and history UI, physical-device validation and deployed API/PostgreSQL integration. The journal and HTTP client are foundations; the composer remains disabled. No SMS or tester messages were sent.

## Foreground synchronization coordinator — 2026-10-04

- Added MessageSync and an app-lifecycle wrapper in main. A signed-in foreground app flushes its scoped journal, lists conversations, downloads ciphertext and acknowledges only through the journal's persist-first receipt path.
- Overlapping triggers share a single cycle. One journal instance is retained per account/device scope. Generation and session checks stop subsequent stages after logout, account change, pause or disposal. Already-started HTTP/storage calls are not forcibly cancelled.
- Each conversation drains at most five 100-message batches per cycle. Successful cycles poll after 15 seconds; errors back off exponentially to 120 seconds and remain available via coordinator state/lastError. An outgoing flush error does not prevent incoming downloads.
- This is foreground REST polling, not real push or OS background execution. The composer and production encryption remain disabled. Errors are observable in the coordinator but still need presentation in the messaging UI. Expired/permanently rejected outbox entries need an explicit user recovery flow; full journals need retention/export/history storage. Provider state still needs atomic persistence with ciphertext.
- Validation: all 63 Flutter tests passed, including eight new coordinator/lifecycle regressions; Flutter analysis reported no issues; changed-file Dart formatting and diff checks passed. Tests use API/journal doubles and Flutter's lifecycle test harness. They do not validate real carrier connections, device background execution or secure-storage crash durability. pubspec.lock was unchanged.
- GitHub checks observed on the preceding commit 7ed1abd59ab7daf6957ee8d3b4b6bc9e837fc3fb: Continuous Integration and SBOM Generation passed. Integration Tests failed at Start Docker Compose Infrastructure; SAST Code Scanning failed at Set up job; Dependency Review failed at its review action. Detailed root causes remain unconfirmed. These checks are release blockers and must be diagnosed and rerun; local test success does not supersede them.

## Release-check diagnosis and repair — 2026-10-04

- Retrieved decoded GitHub job logs rather than relying on failed-step summaries. Flutter CI rejected six unbraced if statements in MessageJournal/MessageSync. Added braces without changing behavior. This supersedes the earlier implication that the local analyzer result established a clean Flutter CI run; fresh CI validation is required.
- SAST failed before analysis because its pinned CodeQL commit did not exist. Resolved the official github/codeql-action v3.28.10 annotated tag and pinned its actual commit b56ba49b26e50535fa1e7f7db0f4f7b4bf65d80d. The run must still complete successfully to establish scan coverage.
- Dependency Review explicitly reports unsupported repository configuration and requests Dependency Graph (plus Advanced Security for private repositories). Repository settings were not changed. This remains an owner/configuration release gate; the failing check was not disabled or masked.
- Docker integration failed pulling MinIO. Inspection also found that no package defines test:integration and Compose contains infrastructure only, while the workflow checks application ports. Replaced this misleading job with a focused PostgreSQL transport integration job using an isolated service database and all migrations. The default Compose MinIO pull problem and full application infrastructure testing remain unresolved.
- Added scripts/transport-integration.mjs: eight concurrent conversation requests converge on one persisted conversation/two members; eight matching envelope submissions converge on one envelope; concurrent delivery/read retries produce one audit row per type; late delivery preserves read status; acknowledged messages leave the pending queue. Fixtures use generated UUIDs and no tester numbers. Cleanup removes only generated fixture users and closes all pools.
- Local validation: 75 API tests passed; API/dependency build/typecheck/lint passed; integration script syntax, imports and isolated-database opt-in guard verified; YAML/Prettier/diff checks passed. Actual PostgreSQL assertions require the new CI job; Docker/PostgreSQL and the temporary Flutter runtime are unavailable locally. No production readiness or deployment claim is made.
- Verified GitHub execution on commit 5a299d68ffde391e81b764fe98cfdce5579efaf3: PostgreSQL Integration Tests passed (run 37182044890), with migrations 001 through 006 and all concurrent transport assertions; SAST Code Scanning passed (run 37182044841). This closes the preceding unknown integration/SAST result for this code increment. It does not validate a complete deployed messaging application, migration cleanup of pre-existing duplicate data, or cryptography.
- Also fixed two existing Markdown formatting failures in MOBILE_DESIGN_SYSTEM.md and PRODUCTION_UI_REVIEW.md. Full repository format check now passes; all 54 workspace build/lint/typecheck tasks pass locally. Dependency Review remains blocked by repository configuration; Flutter's new run must still complete before its result is claimed.

- Fresh Flutter CI passed static analysis and all 63 mobile tests, then Android failed because the Gradle wrapper referenced a Windows-local ZIP. Replaced it with the public Gradle 8.10.2 distribution and aligned Android Gradle Plugin 8.7.0/Kotlin 1.8.22 with the pinned Flutter 3.29.2 template. Restored the Kotlin plugin/JVM configuration and removed AGP 9-only compatibility flags. Android compilation still requires a fresh CI result; release signing remains unfinished.

## Public prekey exchange foundation — 2026-10-04

- Latest preceding Flutter CI on 72b70d3df94663998b543a0adcb56a7634c2125e passed Android compilation, analysis and 63 tests, plus unsigned iOS compilation. These are build results, not signing or physical-device verification.
- Added migration 007_device_prekeys.sql for public device bundles and one-time public prekeys. No private identity/session keys are stored on the server. Consumed-key tombstones survive deletion of the requesting device so replenishment cannot reactivate an already allocated key.
- POST /api/v1/devices/current/prekeys derives ownership from the authenticated session, requires an active account/device, validates canonical public encodings, bounds batches to 100 and available inventory to 1000, and serializes publication. Initial identity/signed bundle is immutable; replenishment accepts identical key IDs without resetting consumption and rejects changed bytes.
- POST /api/v1/conversations/:conversationId/devices/:deviceId/prekey-claims requires two active devices and membership of both accounts. Bundle row locking serializes concurrent allocation; caller-generated UUID claim IDs return the same consumed key on identical retries. Different requests consume distinct keys. Exhaustion and expired bundles fail explicitly; there is no silent signed-prekey-only fallback.
- This initial exchange supports Signal-shaped public material (33-byte version-prefixed keys, 64-byte signatures, registration IDs). The server validates structure, not signature authenticity or private-key possession. The eventual mobile provider must verify signed prekeys, pin peer identities and handle key changes before encryption. Uploading bytes is not proof that encryption works.
- Local validation: all 85 API tests passed (ten new authorization/validation/retry tests); all 30 API/dependency build/typecheck/lint tasks passed. Expanded PostgreSQL integration covers concurrent claim retries, distinct allocations, exhaustion, replenishment, requester deletion and device revocation. Fresh CI must establish the actual database result.
- Production cryptographic provider integration remains unfinished. Official libsignal is actively developed but explicitly does not support outside use; a Dart port is a separate implementation, not automatically equivalent. This increment embeds neither provider and leaves the composer disabled. Provider/dependency review, signature validation, persistent ratchet/session state, atomic crypto/journal commits and two-phone encrypted messaging remain required.
- Initial signed bundles expire within 30 days. Verified identity/signed-prekey rotation, inventory monitoring/replenishment scheduling, claim abuse controls and consumed-key retention policy are deliberately outstanding; this initial API cannot sustain a production installation beyond bundle expiry. Retrying an old claim after expiry/revocation fails. No claim/key material is logged here; no SMS, deployment or tester messaging occurred.
- Verified fresh GitHub execution on 90449751fe0bb11059fda3d3dc4282c3e4a68b7e: Integration Tests run 37191556107 passed, applying migration 007 and all new concurrent allocation, exhaustion, replenishment and requester-deletion/revocation assertions. PR validation, backend tests, build/typecheck/lint, general CI and SAST also passed. These assertions use structural public-byte fixtures; they do not validate signatures or encrypted messaging.
- Owner selected an open-source mobile application. ADR-063 records the official libsignal v0.104.0 integration direction and observed prerequisites: JDK 21/native artifact packaging, signed KEM prekey fields absent from the initial registry, protected/atomic session storage and separate ciphertext per recipient device. No native production provider has been embedded or enabled.

## Modern signed KEM bundle transport — 2026-10-04

- Added migration 008_kem_prekeys.sql and application bundle version 2 for the signed KEM public key, key ID and signature required by the current libsignal candidate. Existing classical version 1 rows remain intact. Bundle version describes our API shape, not the libsignal ciphertext wire version.
- Version 2 requires all KEM fields; version 1 rejects KEM fields. Canonical base64, a 1–4096-byte public-material bound, nonnegative key IDs and 64-byte signatures are checked before writes. Database constraints enforce complete version-appropriate records. Native deserialization and cryptographic signature verification are still required; these structural checks do not establish authenticity.
- Claims return exact persisted KEM material on both first allocation and matching retries. Initial bundles remain immutable, so adding/replacing KEM material, downgrading the bundle version or changing a signature cannot silently change an existing identity/session setup. Rotation and retry snapshots through rotation remain unfinished.
- Local validation: 89 API tests pass; all 30 API/dependency build/typecheck/lint tasks pass. Expanded isolated PostgreSQL CI covers version 2 publication/retry bytes, legacy publication, downgrade/replacement rejection and database shape constraints alongside previous allocation races. Fresh CI results remain pending.
- No native production provider is enabled. Stable libsignal device-address mapping, protected/atomic crypto storage, independent ciphertext per recipient device and encrypted chat UI remain unfinished. KEM fixtures are structural bytes with placeholder signatures, not generated/authenticated provider keys. No SMS, tester messages or deployment occurred.

- Fresh GitHub verification on abfc0da6879e46efc2bf6e6c7d59353b012f76a9: Integration Tests run 37192794033 passed, applying migration 008 and checking modern bundle persistence/retries, downgrade/replacement rejection, SQL shape constraints and all prior transport/prekey concurrency assertions. Backend Unit Tests, TypeScript Lint & Typecheck and SAST passed. This proves the server transport assertions with structural fixtures, not a libsignal handshake or encrypted chat.

## Independent ciphertext for recipient devices — 2026-10-04

- Added migration 009_device_ciphertexts.sql, a strict per-device submission contract and POST /api/v1/conversations/:conversationId/device-envelopes. Batches contain 1–16 unique device UUIDs with canonical nonempty ciphertext and a combined 64 KiB bound. Shared legacy submissions remain compatible; new batches have no common ciphertext in the parent envelope.
- Active sender/recipient accounts, sender-device ownership and both conversation memberships are checked. Recipient device rows and sender are locked in global UUID order. New submissions must cover exactly the active recipient-device inventory observed by the transaction. Devices joining after that observation are not silently added to an accepted batch.
- Idempotency hashes a domain-separated, sorted device/ciphertext set plus routing, protocol and exact timestamps. Matching retries preserve the accepted set even after device inventory changes; changed payloads or metadata fail. A batch and every recipient ciphertext commit atomically with its retry record. Transactions serialize overlapping device sets; throughput/load validation remains required.
- Pending downloads select only the requested device ciphertext and its actual length, while shared legacy records still use the common payload. Per-device records missing ciphertext are excluded rather than falling back to another device's data. Existing device/membership/revocation checks and independent receipts remain active.
- Added authorized GET /api/v1/conversations/:conversationId/recipients/:recipientUserId/devices, returning active device IDs only. Discovery is a snapshot; submission revalidates it. The mobile sender still needs key retrieval/readiness checks and a stale-inventory recovery flow before using this route.
- Local validation: 105 API tests passed, including 16 new per-device authorization, inventory, malformed input, capacity, rollback and retry/discovery regressions. All 30 API/dependency build/typecheck/lint tasks pass. Expanded PostgreSQL integration covers concurrent batch retries, isolated bytes on two devices, independent receipts, inventory changes and revocation. Fresh CI remains pending.
- This implements server delivery of independently supplied ciphertext, not encryption generation. Native libsignal adapters, protected identity/session state and atomic crypto/outbox/history commits remain unfinished; the composer remains disabled. No SMS, tester messages, physical-device tests or deployment occurred.
- Fresh GitHub verification on 1855366d7b1ba2fd31ed6d2b9fc61212b78a6a68: PostgreSQL Integration Tests run 37193500696 passed migration 009, eight concurrent batch requests converging on one accepted batch, distinct downloads on two devices, independent receipts, changed inventory/retry behavior and revocation, plus all prior transport and prekey assertions. These use supplied structural ciphertext, not provider-generated encrypted messages.

## Android native identity persistence foundation — 2026-10-04

- Added exact official libsignal Android/client 0.104.0 dependencies from the upstream Maven repository, restricted to the org.signal group. Updated Kotlin to the upstream 2.2.20 baseline and Android CI to pinned JDK 21 setup; added desugaring 2.1.5 and native identity unit tests. Flutter remains pinned at 3.29.2. Compatibility and actual JNI execution require fresh CI; no local Android SDK/keystore validation is claimed.
- Native IdentityMaterial generates and serializes an actual libsignal identity and registration ID. Tests exercise public identity continuity after restoration, real signatures/tampering, independent generation and rejection of unsupported/truncated records. Private serialized records are not emitted in test assertions or logs.
- DeviceIdentityStore scopes identities to account/device UUIDs. It wraps private records with AES-GCM using a non-exportable AndroidKeyStore wrapping key, scope/version authenticated data and a new storage nonce. Files live in the no-backup directory and use AtomicFile plus explicit file descriptor synchronization before acknowledgement. A process-wide lock serializes creation/restoration. Missing-key/file mismatches, corrupt files and decryption failure fail closed rather than replacing a previously published identity silently.
- The native Flutter channel exposes only public identity, registration ID and provider metadata. It performs storage work off the UI thread and reports sanitized failures. No Dart application route invokes it yet, and supportsDirectMessaging remains false. Identity persistence is not a complete MobileCryptoProvider; the composer stays disabled.
- This does not prove hardware-backed keystore storage, Android physical-device crash durability, multi-process coordination, device/account deletion handling or backup/reinstall recovery. Private bytes still exist transiently in native/Java memory; complete zeroization is not claimed. Identity/prekey/session trust, atomic crypto/outbox/history storage, Android/iOS provider adapters, signed bundle publication and actual encrypted chat remain incomplete.
- Retained the upstream libsignal license and marked new native adapter code AGPL-3.0-only following the owner's open-source direction. Existing source notices are preserved. Native artifact verification, dependency SBOM/notice completeness and corresponding-source release packaging remain required. No signed mobile release, SMS, tester messaging or deployment occurred.

- Added eight isolated Android instrumentation tests covering restoration across store instances/UUID case, non-exportable wrapping keys, account/device isolation, concurrent initialization, tampered ciphertext, missing keys/files, AtomicFile backup recovery and invalid scopes. Android CI now runs these on an API 29 x86_64 emulator with a pinned emulator action. Their actual execution is pending; an emulator result will not establish physical-device crash durability or hardware-backed key storage.
