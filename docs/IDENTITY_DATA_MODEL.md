# Identity Data Model Specification

## PostgreSQL Schema: `001_create_identity_schema.sql`

### Tables Summary

1. `users`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `account_state` VARCHAR(32) NOT NULL CHECK (account_state IN ('pending_profile', 'active', 'restricted', 'suspended', 'deletion_pending', 'deleted'))
   - `terms_accepted_at` TIMESTAMPTZ NOT NULL
   - `privacy_accepted_at` TIMESTAMPTZ NOT NULL
   - `locale` VARCHAR(10) NOT NULL DEFAULT 'ne'
   - `timezone` VARCHAR(64) NOT NULL DEFAULT 'Asia/Kathmandu'
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

2. `phone_identities`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
   - `phone_encrypted` BYTEA NOT NULL
   - `phone_blind_index` VARCHAR(64) NOT NULL
   - `is_primary` BOOLEAN NOT NULL DEFAULT TRUE
   - `verified_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - Unique Index: `phone_blind_index` WHERE `verified_at IS NOT NULL`

3. `user_profiles`
   - `user_id` UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE
   - `display_name` VARCHAR(100) NOT NULL
   - `avatar_object_key` VARCHAR(255) NULL
   - `bio` VARCHAR(255) NULL
   - `profile_visibility` VARCHAR(32) NOT NULL DEFAULT 'contacts_only'
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

4. `usernames`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
   - `username_canonical` VARCHAR(32) NOT NULL UNIQUE CHECK (username_canonical ~ '^[a-z0-9_]{3,20}$')
   - `username_display` VARCHAR(32) NOT NULL
   - `assigned_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `cooldown_until` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

5. `devices`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
   - `installation_id` VARCHAR(128) NOT NULL
   - `device_name` VARCHAR(100) NOT NULL
   - `platform` VARCHAR(32) NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'desktop'))
   - `app_version` VARCHAR(32) NOT NULL
   - `os_version` VARCHAR(32) NOT NULL
   - `notification_token_status` VARCHAR(32) NOT NULL DEFAULT 'disabled'
   - `is_revoked` BOOLEAN NOT NULL DEFAULT FALSE
   - `revoked_at` TIMESTAMPTZ NULL
   - `revoked_reason` VARCHAR(64) NULL
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `last_seen_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

6. `sessions`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
   - `device_id` UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE
   - `session_version` INT NOT NULL DEFAULT 1
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `expires_at` TIMESTAMPTZ NOT NULL
   - `revoked_at` TIMESTAMPTZ NULL

7. `refresh_token_families`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
   - `device_id` UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE
   - `is_compromised` BOOLEAN NOT NULL DEFAULT FALSE
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

8. `refresh_tokens`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `family_id` UUID NOT NULL REFERENCES refresh_token_families(id) ON DELETE CASCADE
   - `token_verifier_hash` VARCHAR(64) NOT NULL UNIQUE
   - `parent_token_id` UUID NULL REFERENCES refresh_tokens(id) ON DELETE SET NULL
   - `replacement_token_id` UUID NULL REFERENCES refresh_tokens(id) ON DELETE SET NULL
   - `expires_at` TIMESTAMPTZ NOT NULL
   - `is_rotated` BOOLEAN NOT NULL DEFAULT FALSE
   - `rotated_at` TIMESTAMPTZ NULL
   - `is_revoked` BOOLEAN NOT NULL DEFAULT FALSE
   - `revoked_at` TIMESTAMPTZ NULL
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

9. `otp_challenges`
   - `id` UUID PRIMARY KEY (UUIDv7)
   - `phone_blind_index` VARCHAR(64) NOT NULL
   - `verifier_hash` VARCHAR(64) NOT NULL
   - `attempts_count` INT NOT NULL DEFAULT 0
   - `max_attempts` INT NOT NULL DEFAULT 3
   - `expires_at` TIMESTAMPTZ NOT NULL
   - `resend_available_at` TIMESTAMPTZ NOT NULL
   - `is_verified` BOOLEAN NOT NULL DEFAULT FALSE
   - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

10. `otp_delivery_attempts`
    - `id` UUID PRIMARY KEY (UUIDv7)
    - `challenge_id` UUID NOT NULL REFERENCES otp_challenges(id) ON DELETE CASCADE
    - `provider_name` VARCHAR(64) NOT NULL
    - `provider_request_id` VARCHAR(128) NULL
    - `status` VARCHAR(32) NOT NULL
    - `cost_amount` NUMERIC(12, 4) NOT NULL DEFAULT 0.0000
    - `cost_currency` VARCHAR(3) NOT NULL DEFAULT 'NPR'
    - `error_code` VARCHAR(64) NULL
    - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

11. `privacy_settings`
    - `user_id` UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE
    - `last_seen_visibility` VARCHAR(32) NOT NULL DEFAULT 'contacts_only'
    - `online_status_visibility` VARCHAR(32) NOT NULL DEFAULT 'contacts_only'
    - `profile_photo_visibility` VARCHAR(32) NOT NULL DEFAULT 'contacts_only'
    - `phone_number_visibility` VARCHAR(32) NOT NULL DEFAULT 'nobody'
    - `read_receipts` BOOLEAN NOT NULL DEFAULT TRUE
    - `phone_discoverability` BOOLEAN NOT NULL DEFAULT FALSE
    - `security_notifications` BOOLEAN NOT NULL DEFAULT TRUE
    - `notification_previews` BOOLEAN NOT NULL DEFAULT TRUE
    - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

12. `security_events`
    - `id` UUID PRIMARY KEY (UUIDv7)
    - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
    - `device_id` UUID NULL REFERENCES devices(id) ON DELETE SET NULL
    - `event_type` VARCHAR(64) NOT NULL
    - `severity` VARCHAR(16) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical'))
    - `user_description_key` VARCHAR(128) NOT NULL
    - `device_context_json` JSONB NOT NULL DEFAULT '{}'::jsonb
    - `internal_metadata_json` JSONB NOT NULL DEFAULT '{}'::jsonb
    - `is_read` BOOLEAN NOT NULL DEFAULT FALSE
    - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

13. `registration_lock_credentials`
    - `user_id` UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE
    - `pin_argon2_hash` VARCHAR(255) NOT NULL
    - `enabled_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    - `updated_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

14. `registration_lock_attempts`
    - `id` UUID PRIMARY KEY (UUIDv7)
    - `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
    - `is_successful` BOOLEAN NOT NULL
    - `ip_address` VARCHAR(45) NULL
    - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

15. `audit_events`
    - `id` UUID PRIMARY KEY (UUIDv7)
    - `actor_type` VARCHAR(32) NOT NULL CHECK (actor_type IN ('user', 'system', 'admin'))
    - `actor_id` UUID NOT NULL
    - `action` VARCHAR(64) NOT NULL
    - `target_type` VARCHAR(64) NOT NULL
    - `target_id` UUID NOT NULL
    - `reason` VARCHAR(255) NULL
    - `correlation_id` VARCHAR(64) NOT NULL
    - `request_id` VARCHAR(64) NOT NULL
    - `outcome` VARCHAR(16) NOT NULL CHECK (outcome IN ('success', 'failure'))
    - `before_state_json` JSONB NULL
    - `after_state_json` JSONB NULL
    - `created_at` TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
