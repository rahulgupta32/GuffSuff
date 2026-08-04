# ADR-007: Dual Protocol Model - REST for Management and WebSockets for Realtime

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

A messaging app requires synchronous request/response patterns for authentication, account management, prekey fetching, and presigned media authorization, alongside bidirectional low-latency push channels for message envelopes and presence.

---

## Decision

We adopt a **Dual-Protocol Communication Model**:

1. **REST APIs (HTTP/2, HTTPS)**: Utilized for stateless management operations (OTP request/verify, profile updates, key bundle publication/retrieval, block/report actions).
2. **WebSockets (`wss://`)**: Utilized for stateful bidirectional messaging (encrypted envelope transport, delivery acknowledgements, typing indicators, presence heartbeat).

---

## Fallback & Reliability
- If WebSocket connection drops, client automatically queues outbound message envelopes locally in SQLite and attempts exponential backoff reconnection.
- Offline undelivered envelopes are held in PostgreSQL and drained immediately upon WebSocket authentication.
