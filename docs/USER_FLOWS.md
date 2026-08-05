# GuffSuff User Flows & Interaction Sequences

> **Document Status**: Complete (Phase 1 Specification)

---

## 1. Onboarding & Registration Sequence

### Flow: First Installation, Language Selection, & Phone OTP Verification

1. **Language Selection**: Client prompts user to select interface language (Nepali Devanagari or English). Saved in local preferences.
2. **Phone Input**: User selects country code (`+977` default) and enters mobile number (e.g. `9841234567`). Client validates number length and format.
3. **API Call**: Client sends `POST /api/v1/auth/otp/request`.
4. **Security Check**: Server enforces IP and phone number rate limits. Formats number to E.164 (`+9779841234567`). Generates 6-digit OTP, saves argon2id hash in Redis with 5-min TTL.
5. **OTP Input**: User inputs 6-digit code. Client calls `POST /api/v1/auth/otp/verify`.
6. **Session Issue**: Server checks hash match and attempt counter. Emits JWT Access Token, Refresh Token, and User ID. Saves session in `sessions` table.
7. **Profile Setup**: User inputs display name and unique username (`@username`). Client calls `POST /api/v1/account/profile`. Server checks username uniqueness in `usernames` table.
8. **Key Generation**: Client generates Identity Keypair and Prekey bundle locally via `packages/crypto-adapter`. Uploads public keys to `POST /api/v1/keys/publish`.

---

## 2. Messaging & Group Operations

### Flow: One-to-One Offline Encrypted Messaging

1. **Compose Message**: User A opens chat with User B and types text.
2. **Device Connection Check**: If device is offline, client stores message in local SQLite with state `QUEUED_OFFLINE`.
3. **Prekey Retrieval**: If session with User B is uninitialized, client fetches User B's public prekey bundle via `GET /api/v1/keys/prekey/:userId/:deviceId`.
4. **Local Encryption**: Client encrypts payload locally via `packages/crypto-adapter`.
5. **WebSocket Transmission**: Upon network reconnect, client transmits `ENVELOPE_DELIVERY` frame over WebSocket.
6. **Server Queueing**: Realtime gateway accepts envelope, writes record to `message_envelopes` table, and checks User B socket state.
7. **Delivery ACK**: User B device receives payload, stores in local SQLite, and responds with `ACK_DELIVERY`. Server updates `message_recipient_states` to `DELIVERED`.

---

## 3. Account Privacy & Administrative Flows

### Flow: Account Deletion Request

1. **User Request**: User selects "Delete Account" in Settings. Prompts for optional PIN / OTP re-authentication.
2. **API Call**: Client calls `DELETE /api/v1/account`.
3. **Database Action**: Server creates record in `account_deletion_requests`, marks user status `DELETION_PENDING`, revokes all active `sessions`, and deletes prekeys.
4. **Purge Job**: `services/worker` background job permanently purges user profile, phone identity, and device keys within 30 days.
