-- Submission acceptance is not handset delivery, and billing is not known yet.
ALTER TABLE otp_delivery_attempts ALTER COLUMN cost_amount DROP NOT NULL;
ALTER TABLE otp_delivery_attempts ALTER COLUMN cost_currency DROP NOT NULL;
