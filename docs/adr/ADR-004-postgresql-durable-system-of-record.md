# ADR-004: PostgreSQL as Durable System of Record

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Database Architect, GuffSuff Lead Architecture Team
- **Decision Status**: Proposed

---

## Context

GuffSuff requires a primary transactional database for users, phone identities, devices, key bundles, conversation metadata, undelivered E2EE message envelopes, group memberships, and administrative audit logs.

---

## Decision

We select **PostgreSQL** as the authoritative durable system of record.

### Versioning & Deployment Policy

- The specified version (e.g., PostgreSQL 16) represents an initial deployment baseline rather than a permanent architectural constraint.
- Production deployments MUST enforce:
  1. **Supported Release**: Use actively maintained active LTS releases.
  2. **Security-Patch Policy**: Timely application of upstream security patches within 14 days of release.
  3. **Upgrade Policy**: Scheduled major-version upgrade path with pre-release migration testing.
  4. **Compatibility Testing**: Continuous integration tests executed against target major versions.
  5. **No Floating Image Tags**: Container deployments MUST pin exact immutable image tags (e.g. `postgres:16.4-alpine3.20`), strictly prohibiting floating tags (`latest`, `16-alpine`).

### Key Database Conventions

- **Identifiers**: UUIDv7 (time-ordered sequential UUIDs) for primary keys.
- **Partitioning**: Range partitioning by month on high-volume tables (`message_envelopes`, `security_events`).
