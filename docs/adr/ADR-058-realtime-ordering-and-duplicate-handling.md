# ADR-058: Realtime Ordering and Duplicate Handling

## Context

WebSocket connections can experience temporary disconnections, event re-ordering, or duplicate delivery events.

## Decision

1. Realtime delivery events contain monotonically increasing server acceptance timestamps and envelope UUIDv7 identifiers.
2. Mobile client applies local duplicate suppression using `envelope_id` set indexing.
3. Server-side PostgreSQL database remains the single durable system of record; Redis provides ephemeral WebSocket connection routing only.

## Consequences

- Prevents UI duplicate renders and guarantees state consistency across reconnection cycles.
