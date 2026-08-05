# ADR-003: TypeScript and NestJS for Backend Services

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff requires a robust, scalable backend architecture for handling REST APIs, WebSocket real-time messaging routing, background queue processing, and administrative controls.

---

## Decision

We select **TypeScript with NestJS** on Node.js (Active LTS release) as the standardized backend framework across `services/api`, `services/realtime`, and `services/worker`.

### Key Technical Stack

- **Language & Runtime**: TypeScript 5.x on Node.js 20 LTS.
- **Framework**: NestJS 10.x utilizing modular architecture (`@nestjs/core`, `@nestjs/websockets`, `@nestjs/microservices`).
- **Validation & Serialization**: `class-validator`, `class-transformer`, Zod / OpenAPI contract validation.
- **ORMs & Database Drivers**: `pg`, Prisma or Kysely / TypeORM with raw query support for performance-critical envelope routing.

---

## Alternatives Considered

- **Go (Golang)**: Considered for high WebSocket concurrency. Deferred because NestJS handles predicted initial load comfortably (10k+ concurrent connections per instance with Redis adapter), while TypeScript allows 100% shared API contract types between backend services, admin console, and contract packages. Go may be re-evaluated later only for a narrow high-throughput routing microservice if benchmarks fail SLO targets.

---

## Consequences & Implications

- **Pros**: Unified language (TypeScript) across backend, shared contract packages, and admin frontend; rapid development; mature ecosystem for OpenAPI generation and NestJS dependency injection.
- **Cons**: Higher memory footprint per pod compared to compiled Go binaries.
- **Operational**: Node.js backend services will be containerized with lightweight Alpine base images and tuned garbage collection options.

---

## Revisit Conditions

Re-evaluate Go microservice extraction if WebSocket connection density per node cannot satisfy sub-50ms message fan-out under load testing (>50k active sockets per server instance).
