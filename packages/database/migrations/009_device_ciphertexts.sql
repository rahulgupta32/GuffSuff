BEGIN;
ALTER TABLE message_envelopes ADD COLUMN IF NOT EXISTS payload_mode VARCHAR(16) NOT NULL DEFAULT 'shared';
ALTER TABLE message_envelopes ALTER COLUMN opaque_payload DROP NOT NULL;
ALTER TABLE message_envelopes DROP CONSTRAINT IF EXISTS message_envelopes_payload_mode_check;
ALTER TABLE message_envelopes ADD CONSTRAINT message_envelopes_payload_mode_check CHECK (
  (payload_mode = 'shared' AND opaque_payload IS NOT NULL)
  OR (payload_mode = 'per_device' AND opaque_payload IS NULL)
);
ALTER TABLE message_recipient_devices ADD COLUMN IF NOT EXISTS opaque_payload BYTEA;
ALTER TABLE message_recipient_devices DROP CONSTRAINT IF EXISTS message_recipient_devices_payload_size;
ALTER TABLE message_recipient_devices ADD CONSTRAINT message_recipient_devices_payload_size CHECK (
  opaque_payload IS NULL OR octet_length(opaque_payload) BETWEEN 1 AND 65536
);
COMMIT;
