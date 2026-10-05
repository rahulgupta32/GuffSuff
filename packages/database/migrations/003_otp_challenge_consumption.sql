-- Consume verified challenges atomically with account registration.
ALTER TABLE otp_challenges ADD COLUMN IF NOT EXISTS consumed_at TIMESTAMPTZ NULL;
