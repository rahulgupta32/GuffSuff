# ADR-005: Redis for Ephemeral Coordination and Caching

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

Real-time messaging platforms require high-throughput sub-millisecond coordination for WebSocket socket routing across multiple API/realtime nodes, rate-limiting, short-lived presigned session state, and presence tracking.

---

## Decision

We select **Redis 7.2+** as our in-memory data store for ephemeral state and distributed messaging coordination.

### Approved Use Cases
1. **Rate Limiting**: Sliding window rate limits for OTP requests, login attempts, contact discovery queries, and message sends.
2. **WebSocket Pub/Sub Routing**: Relaying encrypted message envelopes between realtime gateway instances for online recipient devices.
3. **Ephemeral Presence**: Short-lived online/offline connection state keys with aggressive TTL (Time-To-Live).
4. **Distributed Locks**: Redlock algorithm for idempotent job execution in `services/worker`.

### Prohibited Use Cases
- Redis **MUST NOT** be used as the sole durable store for message envelopes, user account records, or private keys.

---

## Alternatives Considered

- **Memcached**: Rejected due to lack of built-in Pub/Sub capabilities and complex data structures (Sorted Sets, Hashes) needed for rate limiting.

---

## Consequences & Implications

- Fast sub-millisecond latency for Pub/Sub and rate limit evaluation.
- Failure of Redis cluster must degrade gracefully (e.g., fall back to database state for critical auth checks) without causing message data loss.
