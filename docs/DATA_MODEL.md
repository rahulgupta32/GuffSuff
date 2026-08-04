# GuffSuff Database Schema & Data Model Specification

> **Document Status**: Complete (Phase 1 Specification)  
> **Database Engine**: PostgreSQL 16+  
> **Primary Key Strategy**: UUIDv7 (Time-ordered sequential 128-bit UUIDs)

---

## 1. Data Classification Rules

Every table column in GuffSuff is classified into one of six security tiers:
1. **Public**: Publicly queryable (e.g. `@username`).
2. **Account-Private**: Restricted to authenticated user (e.g. phone number in isolated table).
3. **Operational**: System routing metadata (e.g. device ID, socket connection state).
4. **Encrypted Envelope**: Opaque base64 binary ciphertext (server cannot decrypt).
5. **Security-Sensitive**: Argon2id hashes, refresh tokens, OTP attempt counters.
6. **Admin-Restricted**: Audit records and trust & safety flags.

---

## 2. Relational Schema Definitions

### Identity & Authentication

#### `users`
- **Purpose**: Core user account root record.
- **PK**: `id` UUIDv7 (`PRIMARY KEY`)
- **Fields**: `created_at` TIMESTAMPTZ, `updated_at` TIMESTAMPTZ, `status` VARCHAR(20) DEFAULT 'ACTIVE', `registration_pin_hash` TEXT.
- **Data Classification**: Operational / Account-Private.
- **Retention**: Retained until account deletion.

#### `phone_identities`
- **Purpose**: E.164 normalized phone numbers (+977...) separated from `users` for security isolation.
- **PK**: `id` UUIDv7
- **FK**: `user_id` -> `users(id)` ON DELETE CASCADE (`UNIQUE`)
- **Fields**: `phone_number_e164` VARCHAR(20) (`UNIQUE`), `country_code` VARCHAR(5), `is_verified` BOOLEAN.
- **Indexes**: `idx_phone_e164` ON (`phone_number_e164`)
- **Data Classification**: Account-Private (Restricted Access).

#### `usernames`
- **Purpose**: Unique platform `@username` handle.
- **PK**: `id` UUIDv7
- **FK**: `user_id` -> `users(id)` ON DELETE CASCADE (`UNIQUE`)
- **Fields**: `username` VARCHAR(30) (`UNIQUE`), `allocated_at` TIMESTAMPTZ.
- **Indexes**: `idx_username_lower` ON (LOWER(`username`))

#### `user_profiles`
- **Purpose**: Public profile details.
- **PK**: `id` UUIDv7
- **FK**: `user_id` -> `users(id)` ON DELETE CASCADE (`UNIQUE`)
- **Fields**: `display_name` VARCHAR(100), `avatar_object_key` VARCHAR(255), `bio` TEXT, `updated_at` TIMESTAMPTZ.

#### `devices`
- **Purpose**: Registered physical devices bound to user account.
- **PK**: `id` UUIDv7
- **FK**: `user_id` -> `users(id)` ON DELETE CASCADE
- **Fields**: `device_identifier` VARCHAR(64), `device_name` VARCHAR(100), `platform` VARCHAR(10), `app_version` VARCHAR(20), `last_active_at` TIMESTAMPTZ.
- **Constraints**: `UNIQUE(user_id, device_identifier)`

#### `device_key_bundles`
- **Purpose**: Public cryptographic prekeys for initiating E2EE sessions.
- **PK**: `id` UUIDv7
- **FK**: `device_id` -> `devices(id)` ON DELETE CASCADE (`UNIQUE`)
- **Fields**: `identity_key_pub` TEXT, `signed_prekey_pub` TEXT, `signed_prekey_sig` TEXT, `one_time_prekeys_json` JSONB.

#### `sessions`
- **Purpose**: Server-side revocable refresh token sessions.
- **PK**: `id` UUIDv7
- **FK**: `user_id` -> `users(id)`, `device_id` -> `devices(id)`
- **Fields**: `refresh_token_hash` VARCHAR(64) (`UNIQUE`), `expires_at` TIMESTAMPTZ, `revoked_at` TIMESTAMPTZ.

---

### Messaging & Group Domain

#### `conversations`
- **Purpose**: Conversation channel container (Direct 1:1 or Group).
- **PK**: `id` UUIDv7
- **Fields**: `type` VARCHAR(10) ('DIRECT', 'GROUP'), `created_at` TIMESTAMPTZ.

#### `conversation_members`
- **Purpose**: Membership mapping for direct and group chats.
- **PK**: `id` UUIDv7
- **FK**: `conversation_id` -> `conversations(id)`, `user_id` -> `users(id)`
- **Constraints**: `UNIQUE(conversation_id, user_id)`

#### `groups`
- **Purpose**: Group-specific metadata.
- **PK**: `id` UUIDv7
- **FK**: `conversation_id` -> `conversations(id)` (`UNIQUE`)
- **Fields**: `title` VARCHAR(100), `avatar_object_key` VARCHAR(255), `created_by_user_id` -> `users(id)`.

#### `group_members`
- **Purpose**: Member roles in groups.
- **PK**: `id` UUIDv7
- **FK**: `group_id` -> `groups(id)`, `user_id` -> `users(id)`
- **Fields**: `role` VARCHAR(20) DEFAULT 'MEMBER' ('OWNER', 'ADMIN', 'MEMBER').

#### `group_invites`
- **Purpose**: Short-lived group invite links.
- **PK**: `id` UUIDv7
- **FK**: `group_id` -> `groups(id)`
- **Fields**: `invite_token_hash` VARCHAR(64) (`UNIQUE`), `expires_at` TIMESTAMPTZ.

#### `message_envelopes` (Partitioned by Month)
- **Purpose**: Server-side opaque encrypted message container. ZERO plaintext content.
- **PK**: `id` UUIDv7
- **FK**: `conversation_id` -> `conversations(id)`, `sender_device_id` -> `devices(id)`
- **Fields**: `client_idempotency_key` VARCHAR(64), `encrypted_payload` TEXT (Base64), `created_at` TIMESTAMPTZ, `expires_at` TIMESTAMPTZ.
- **Indexes**: `idx_envelope_conv_time` ON (`conversation_id`, `created_at` DESC)

#### `message_recipient_states`
- **Purpose**: Delivery & read receipts per recipient device.
- **PK**: `id` UUIDv7
- **FK**: `envelope_id` -> `message_envelopes(id)`, `recipient_device_id` -> `devices(id)`
- **Fields**: `state` VARCHAR(20) ('PENDING', 'DELIVERED', 'READ'), `updated_at` TIMESTAMPTZ.

#### `message_edits` & `message_deletions`
- **Immutable Envelope Event Model**: Message edits and deletions are **NOT server-side database mutations of old records**. Instead, they are published as new encrypted event envelopes referencing `parent_envelope_id`. Client devices apply the edit/deletion locally upon decrypting the event envelope.

#### `attachments` & `attachment_uploads`
- **Purpose**: Metadata references for client-side encrypted media files uploaded to Object Storage.
- **Fields**: `object_key` VARCHAR(255) (`UNIQUE`), `size_bytes` BIGINT, `mime_type` VARCHAR(100), `checksum_sha256` VARCHAR(64).

---

### Privacy, Security & Administration

#### `privacy_settings`, `contact_discovery_consents`, `blocks`, `reports`, `abuse_signals`, `notification_devices`, `security_events`, `admin_users`, `admin_roles`, `admin_user_roles`, `admin_audit_events`, `data_export_requests`, `account_deletion_requests`.
- Defined with strict relational integrity, UUIDv7 PKs, immutable timestamps, and audit log foreign keys.
