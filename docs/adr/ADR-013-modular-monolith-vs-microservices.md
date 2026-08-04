# ADR-013: Modular Monolith Architecture with Separately Deployable Microservices

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

We evaluated whether GuffSuff's backend should be built as fully independent microservices with distributed IPC from day one versus a modular NestJS monolith with independently runnable service entry points.

---

## Decision

We choose **Modular NestJS Architecture with Shared Domain Packages (Option B)**.

### Architecture Structure
- The backend is authored as modular NestJS domains (`AuthModule`, `AccountModule`, `DeviceModule`, `MessageModule`, `RealtimeGatewayModule`, `WorkerModule`).
- In local development, all modules run in a single NestJS process for developer simplicity.
- In staging and production, separate entry-point binaries are compiled and deployed as distinct containers:
  - `services/api` (REST API gateway)
  - `services/realtime` (WebSocket gateway)
  - `services/worker` (BullMQ background worker)

---

## Rationale
- Prevents premature microservice fragmentation overhead while maintaining strict module boundaries and independent horizontal container autoscaling in production.
