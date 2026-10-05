-- Retain the earliest acknowledgement when older retries created duplicates.
-- This migration is transactional: no writes can race between cleanup and
-- installing the uniqueness constraint. Schedule during a maintenance window
-- for a large existing table; this lock blocks receipt writes while it runs.
BEGIN;
LOCK TABLE message_acknowledgements IN SHARE ROW EXCLUSIVE MODE;
WITH ranked AS (
  SELECT id, ROW_NUMBER() OVER (
    PARTITION BY envelope_id, recipient_device_id, ack_type
    ORDER BY acknowledged_at, id
  ) AS occurrence
  FROM message_acknowledgements
)
DELETE FROM message_acknowledgements a USING ranked r
WHERE a.id = r.id AND r.occurrence > 1;
CREATE UNIQUE INDEX IF NOT EXISTS idx_message_acknowledgements_unique
  ON message_acknowledgements(envelope_id, recipient_device_id, ack_type);
COMMIT;
