# ADR-053: Per-Device Durable Delivery Model

## Context

GuffSuff users may own multiple registered active devices (e.g. mobile, desktop).

## Decision

1. Upon envelope submission, API resolves all active, unrevoked recipient devices owned by the target user.
2. Creates one `message_recipient_devices` record per eligible device.
3. Revoked recipient devices are excluded from initial fan-out and future delivery attempts.
4. Delivery status is tracked independently per device (`accepted`, `queued`, `routed`, `delivered`, `read`).

## Consequences

- Supports multi-device routing with independent delivery state machines per device.
