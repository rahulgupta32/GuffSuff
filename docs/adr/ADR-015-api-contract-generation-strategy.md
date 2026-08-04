# ADR-015: API Contract Generation & Type Safety Strategy

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

To prevent API contract drift between `services/api`, `apps/admin`, and `apps/mobile`, a unified schema generation pipeline is required.

---

## Decision

We adopt **OpenAPI 3.0 (Swagger) Schema Generation from NestJS DTOs** as the single source of truth.

### Workflow
1. NestJS API controllers and DTOs use `@nestjs/swagger` annotations and Zod validation schemas.
2. An automated CI step generates `packages/contracts/openapi.json`.
3. Client SDKs for Flutter/Dart (`dio` models) and TypeScript (`apps/admin`) are auto-generated via `openapi-generator-cli`.
