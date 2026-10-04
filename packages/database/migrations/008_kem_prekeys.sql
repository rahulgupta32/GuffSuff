-- Version 2 adds signed KEM public material; no private keys are stored.
BEGIN;
ALTER TABLE device_key_bundles ADD COLUMN IF NOT EXISTS kem_prekey_id INTEGER;
ALTER TABLE device_key_bundles ADD COLUMN IF NOT EXISTS kem_prekey BYTEA;
ALTER TABLE device_key_bundles ADD COLUMN IF NOT EXISTS kem_prekey_signature BYTEA;
ALTER TABLE device_key_bundles DROP CONSTRAINT IF EXISTS device_key_bundles_protocol_version_check;
ALTER TABLE device_key_bundles ADD CONSTRAINT device_key_bundles_protocol_version_check CHECK (protocol_version IN (1, 2));
ALTER TABLE device_key_bundles DROP CONSTRAINT IF EXISTS device_key_bundles_kem_shape;
ALTER TABLE device_key_bundles ADD CONSTRAINT device_key_bundles_kem_shape CHECK (
  (protocol_version = 1 AND kem_prekey_id IS NULL AND kem_prekey IS NULL AND kem_prekey_signature IS NULL)
  OR
  (protocol_version = 2 AND kem_prekey_id IS NOT NULL AND kem_prekey IS NOT NULL AND kem_prekey_signature IS NOT NULL
   AND kem_prekey_id BETWEEN 0 AND 2147483647
   AND octet_length(kem_prekey) BETWEEN 1 AND 4096
   AND octet_length(kem_prekey_signature) = 64)
);
COMMIT;
