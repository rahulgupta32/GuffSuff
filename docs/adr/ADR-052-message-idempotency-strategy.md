# ADR-052: Message Idempotency Strategy

## Context
Network retries and mobile reconnects can lead to duplicate envelope submissions.

## Decision
1. Client generates cryptographically random UUIDv7/256-bit string as `idempotencyKey` per logical message submission.
2. Uniqueness is scoped per sender device in `message_idempotency_keys(sender_device_id, idempotency_key)`.
3. Re-submitting with identical payload digest returns the cached server acceptance response.
4. Re-submitting with a different payload digest under the same idempotency key is rejected with HTTP 400 Bad Request.

## Consequences
- Prevents duplicate message storage while permitting safe client network retries.
