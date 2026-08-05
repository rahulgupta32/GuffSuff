# ADR-055: Offline Retry and Dead-Letter Policy

## Context
Recipient devices may be offline, sleeping, or temporarily unreachable.

## Decision
1. Worker service periodically processes pending delivery records (`delivery_status IN ('accepted', 'queued')`).
2. Retries use exponential backoff with jitter up to 5 max attempts.
3. Expired envelopes (`expires_at <= NOW()`) are automatically marked `expired` and omitted from future delivery batches.
4. Permanent delivery failures enter dead-letter status `permanently_failed` with zero payload exposure in worker logs.

## Consequences
- Guarantees at-least-once offline delivery while protecting worker memory and log streams.
