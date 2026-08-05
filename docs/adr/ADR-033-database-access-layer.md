# ADR-033: Database Access Layer and Migration Strategy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Database Architect, Backend Lead
- **Decision Status**: Proposed

## Context

GuffSuff requires a type-safe database layer for PostgreSQL 16 with explicit migration safety, transaction support, SQL query visibility, and zero magic auto-migrations in production.

## Decision

We select **Kysely** with **Prisma Client / Migration Engine** in `packages/database`.

- **Query Builder**: Kysely / Prisma Client for zero-cost type-safe SQL queries.
- **Migrations**: Explicit SQL migrations managed via Prisma CLI. Production startup MUST NOT auto-apply migrations.
