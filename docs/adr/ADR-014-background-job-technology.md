# ADR-014: Background Job Processing Technology Evaluation

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

`services/worker` requires a reliable background job processing engine for delayed push notifications, media thumbnail cleanup, account export data packaging, and scheduled retention deletion jobs.

---

## Decision

We select **BullMQ (Redis-backed queue engine for Node.js/TypeScript)** for `services/worker`.

### Key Capabilities

- Retries with exponential backoff.
- Dead-letter queues (DLQ) for unhandled errors.
- Concurrency controls and rate-limited job execution.
- Delayed jobs and scheduled cron-like repeatable jobs.
