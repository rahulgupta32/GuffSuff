-- Public material only. Private identity/session keys never belong on the server.
BEGIN;
CREATE TABLE IF NOT EXISTS device_key_bundles (
  device_id UUID PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
  protocol_version INTEGER NOT NULL CHECK (protocol_version = 1),
  registration_id INTEGER NOT NULL CHECK (registration_id BETWEEN 1 AND 16380),
  identity_key BYTEA NOT NULL CHECK (octet_length(identity_key) = 33),
  signed_prekey_id INTEGER NOT NULL CHECK (signed_prekey_id BETWEEN 0 AND 2147483647),
  signed_prekey BYTEA NOT NULL CHECK (octet_length(signed_prekey) = 33),
  signed_prekey_signature BYTEA NOT NULL CHECK (octet_length(signed_prekey_signature) = 64),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS device_one_time_prekeys (
  device_id UUID NOT NULL REFERENCES device_key_bundles(device_id) ON DELETE CASCADE,
  key_id INTEGER NOT NULL CHECK (key_id BETWEEN 0 AND 2147483647),
  public_key BYTEA NOT NULL CHECK (octet_length(public_key) = 33),
  -- Keep consumed-key tombstones even after the claiming device/account is deleted.
  claimed_by_device_id UUID,
  claim_id UUID,
  claimed_at TIMESTAMPTZ,
  PRIMARY KEY(device_id, key_id),
  UNIQUE(device_id, public_key),
  CHECK ((claimed_by_device_id IS NULL AND claim_id IS NULL AND claimed_at IS NULL)
      OR (claimed_by_device_id IS NOT NULL AND claim_id IS NOT NULL AND claimed_at IS NOT NULL))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_prekey_claim_retry
  ON device_one_time_prekeys(device_id, claimed_by_device_id, claim_id) WHERE claim_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prekey_available
  ON device_one_time_prekeys(device_id, key_id) WHERE claim_id IS NULL;
COMMIT;
