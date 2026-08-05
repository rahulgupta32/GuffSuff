-- Migration 002: Create Opaque Encrypted Envelope Message Transport Schema for GuffSuff Phase 5

CREATE TABLE IF NOT EXISTS direct_conversations (
  id UUID PRIMARY KEY,
  participant1_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  participant2_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_different_participants CHECK (participant1_user_id <> participant2_user_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_direct_conversations_pair
  ON direct_conversations (LEAST(participant1_user_id, participant2_user_id), GREATEST(participant1_user_id, participant2_user_id));

CREATE TABLE IF NOT EXISTS conversation_members (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES direct_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unq_conversation_member UNIQUE (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON conversation_members(user_id);

CREATE TABLE IF NOT EXISTS message_envelopes (
  id UUID PRIMARY KEY,
  client_idempotency_key VARCHAR(64) NOT NULL,
  conversation_id UUID NOT NULL REFERENCES direct_conversations(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  protocol_version INT NOT NULL DEFAULT 1,
  payload_byte_length INT NOT NULL CHECK (payload_byte_length <= 65536), -- 64KB max envelope
  opaque_payload BYTEA NOT NULL,
  opaque_payload_content_type VARCHAR(64) NOT NULL DEFAULT 'application/x-guffsuff-opaque-envelope',
  transport_flags INT NOT NULL DEFAULT 0,
  client_created_at TIMESTAMPTZ NOT NULL,
  server_accepted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_message_envelopes_conversation ON message_envelopes(conversation_id);
CREATE INDEX IF NOT EXISTS idx_message_envelopes_sender ON message_envelopes(sender_user_id, sender_device_id);
CREATE INDEX IF NOT EXISTS idx_message_envelopes_recipient ON message_envelopes(recipient_user_id);

CREATE TABLE IF NOT EXISTS message_recipient_devices (
  id UUID PRIMARY KEY,
  envelope_id UUID NOT NULL REFERENCES message_envelopes(id) ON DELETE CASCADE,
  recipient_device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  delivery_status VARCHAR(32) NOT NULL DEFAULT 'queued'
    CHECK (delivery_status IN ('accepted', 'queued', 'routed', 'delivered', 'read', 'expired', 'revoked_recipient', 'permanently_failed')),
  delivery_attempts_count INT NOT NULL DEFAULT 0,
  last_attempted_at TIMESTAMPTZ NULL,
  delivered_at TIMESTAMPTZ NULL,
  read_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unq_envelope_recipient_device UNIQUE (envelope_id, recipient_device_id)
);

CREATE INDEX IF NOT EXISTS idx_recipient_devices_lookup ON message_recipient_devices(recipient_device_id, delivery_status);

CREATE TABLE IF NOT EXISTS message_delivery_attempts (
  id UUID PRIMARY KEY,
  recipient_device_record_id UUID NOT NULL REFERENCES message_recipient_devices(id) ON DELETE CASCADE,
  status VARCHAR(32) NOT NULL,
  error_code VARCHAR(64) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS message_acknowledgements (
  id UUID PRIMARY KEY,
  envelope_id UUID NOT NULL REFERENCES message_envelopes(id) ON DELETE CASCADE,
  recipient_device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  ack_type VARCHAR(32) NOT NULL CHECK (ack_type IN ('delivery', 'read')),
  acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_message_acknowledgements_envelope ON message_acknowledgements(envelope_id);

CREATE TABLE IF NOT EXISTS message_read_states (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES direct_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_read_envelope_id UUID NULL REFERENCES message_envelopes(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unq_user_conversation_read_state UNIQUE (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS message_idempotency_keys (
  id UUID PRIMARY KEY,
  sender_device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  idempotency_key VARCHAR(64) NOT NULL,
  envelope_id UUID NOT NULL REFERENCES message_envelopes(id) ON DELETE CASCADE,
  payload_digest_sha256 VARCHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unq_device_idempotency UNIQUE (sender_device_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS message_transport_events (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES direct_conversations(id) ON DELETE CASCADE,
  envelope_id UUID NULL REFERENCES message_envelopes(id) ON DELETE CASCADE,
  event_type VARCHAR(64) NOT NULL,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_message_transport_events_conv ON message_transport_events(conversation_id);
