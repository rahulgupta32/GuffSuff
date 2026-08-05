# ADR-013: Modular Monolith Architecture with Separately Deployable Backend Service Entry Points

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Terminology Clarification (Phase 3 Amendment)

> **Architectural Boundary Note**: GuffSuff's backend is structured as a modular NestJS application with independently runnable backend entry points (`api`, `realtime`, `worker`) sharing approved internal packages. It is NOT a mature microservice architecture (which requires independent deployment lifecycles, service-specific data ownership, independent SLA/compatibility policies, distributed operational ownership, and benchmarked independent scaling evidence). The term "microservices" is strictly replaced with "backend services", "independently runnable backend entry points", or "modular service applications".

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
