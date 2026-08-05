# ADR-005: Redis for Ephemeral Coordination and Caching

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Backend Architect, GuffSuff Lead Architecture Team
- **Decision Status**: Proposed

---

## Context

Real-time messaging platforms require high-throughput sub-millisecond coordination for WebSocket socket routing across multiple API/realtime nodes, rate-limiting, short-lived presigned session state, and presence tracking.

---

## Decision

We select **Redis** as our in-memory data store for ephemeral state and distributed messaging coordination.

### Versioning & Deployment Policy

- Specified versions (e.g. Redis 7.2) represent an initial deployment baseline rather than a permanent architectural constraint.
- Production deployments MUST enforce:
  1. **Supported Release**: Use actively supported releases with vendor security maintenance.
  2. **Security-Patch Policy**: Rapid application of critical vulnerability patches (CVEs).
  3. **Upgrade Policy**: Automated testing of client driver compatibility before cluster upgrades.
  4. **No Floating Image Tags**: Container manifests MUST pin explicit immutable image tags (e.g., `redis:7.2.5-alpine`), prohibiting floating tags (`latest`, `7-alpine`).

### Approved Use Cases

1. **Rate Limiting**: Sliding window rate limits for OTP requests, login attempts, contact discovery queries, and message sends.
2. **WebSocket Pub/Sub Routing**: Relaying encrypted message envelopes between realtime gateway instances.
3. **Ephemeral Presence**: Short-lived connection state keys with aggressive TTL.
