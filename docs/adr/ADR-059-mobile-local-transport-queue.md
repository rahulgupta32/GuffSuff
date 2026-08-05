# ADR-059: Mobile Local Transport Queue

## Context
Mobile clients must queue outbound messages locally when offline or reconnecting.

## Decision
1. Mobile app maintains a local outbound queue with states `queued`, `sending`, `accepted`, `delivered`, `read`, `failed`.
2. Outbound envelopes are assigned a random client `idempotencyKey` prior to initial API request.
3. Network reconnection automatically triggers flush of local queued messages.

## Consequences
- Ensures smooth offline-first user experience and predictable retries.
