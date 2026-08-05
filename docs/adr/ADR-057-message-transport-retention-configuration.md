# ADR-057: Message Transport Retention Configuration

## Context
Data retention policies for delivered envelopes and idempotency keys must remain flexible.

## Decision
1. Retention windows are configurable via environment variables and marked `Proposed` in defaults.
2. Undelivered envelopes default to 30-day TTL before expiration.
3. Delivered envelopes default to 7-day server purge window unless disappearing message policies specify shorter windows.
4. Idempotency records are retained for 7 days to cover client reconnect retry windows.

## Consequences
- Balances server storage optimization with mobile offline delivery windows.
