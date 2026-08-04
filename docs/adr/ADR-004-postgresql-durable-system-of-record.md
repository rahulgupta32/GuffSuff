# ADR-004: PostgreSQL as Durable System of Record

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff requires a primary transactional database for users, phone identities, devices, key bundles, conversation metadata, undelivered E2EE message envelopes, group memberships, and administrative audit logs.

---

## Decision

We select **PostgreSQL 16+** as the authoritative durable system of record.

### Key Database Conventions
- **Identifiers**: UUIDv7 (time-ordered sequential UUIDs) for primary keys to preserve index locality while preventing ID enumeration attacks.
- **Schema Management**: Versioned migration scripts with explicit up/down rollbacks.
- **Partitioning**: Range partitioning by month on high-volume tables (`message_envelopes`, `security_events`, `admin_audit_events`).
- **Integrity**: Strict foreign key constraints, unique indexes, and transactional boundaries.

---

## Alternatives Considered

- **MongoDB / NoSQL**: Rejected due to lack of strict relational constraints for security RBAC, key bundles, and transactional audit trails.
- **Firebase Firestore**: Explicitly rejected due to vendor lock-in, unsuited query cost behavior at scale, data residency limitations, and inability to run custom E2EE payload validation.

---

## Consequences & Implications

- **Pros**: Proven ACID compliance, rich extension ecosystem (`pgcrypto`, `pg_trgm`), robust backup tooling (`pg_dump`, `WAL-G` for point-in-time recovery).
- **Cons**: Requires active vacuuming and connection pooling (`PgBouncer`) under high concurrency.

---

## Revisit Conditions

Partitioning strategy and archiving schedules will be evaluated if `message_envelopes` table exceeds 100 million active rows.
