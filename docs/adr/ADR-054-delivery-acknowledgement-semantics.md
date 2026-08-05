# ADR-054: Delivery Acknowledgement Semantics

## Context
Message delivery status MUST be accurate and monotonic across offline retries and multi-device connections.

## Decision
1. Delivery state transitions are strictly monotonic (`accepted` -> `queued` -> `routed` -> `delivered` -> `read`).
2. A message envelope is considered `delivered` only when the recipient device explicitly sends `POST /api/v1/envelopes/:id/delivered` or `client.message.delivered`.
3. Push notification dispatch does NOT constitute message delivery.
4. Read receipt acknowledgement requires valid conversation membership.

## Consequences
- Prevents false delivery state assertions and ensures accurate multi-device state tracking.
