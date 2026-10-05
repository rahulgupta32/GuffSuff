-- Legacy families cannot be safely linked to one session. Revoke them and
-- require reauthentication instead of guessing a session relationship.
ALTER TABLE refresh_token_families ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES sessions(id);
UPDATE refresh_token_families SET is_compromised = true WHERE session_id IS NULL;
UPDATE refresh_tokens SET is_revoked = true, revoked_at = CURRENT_TIMESTAMP
WHERE family_id IN (SELECT id FROM refresh_token_families WHERE session_id IS NULL);
CREATE INDEX IF NOT EXISTS idx_refresh_families_session ON refresh_token_families(session_id);
