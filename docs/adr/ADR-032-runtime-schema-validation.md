# ADR-032: Runtime Schema Validation and API Contract Strategy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead API Architect, Security Lead
- **Decision Status**: Proposed

## Context

Shared transport contracts require runtime schema validation and static TypeScript type inference to prevent invalid payloads from reaching service handlers.

## Decision

We adopt **Zod** in `packages/contracts` for runtime schema validation and static type inference (`z.infer<typeof Schema>`). OpenAPI 3.0 metadata is generated directly from NestJS DTO wrappers.
