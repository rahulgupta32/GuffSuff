# ADR-011: UTC Storage with Presentation-Layer Calendar Conversion

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff operates primarily in Nepal (`Asia/Kathmandu` timezone, UTC+05:45) where the official national calendar is Bikram Sambat (BS), alongside standard ISO Gregorian calendar usage.

---

## Decision

1. **Storage & Core Protocol**: All backend services, database timestamps, message headers, and API contracts MUST store and transmit timestamps strictly in **UTC (ISO 8601 string format e.g. `YYYY-MM-DDTHH:mm:ss.sssZ`)**.
2. **Presentation Boundary**: Conversion to `Asia/Kathmandu` local time and optional Bikram Sambat (BS) date formatting is executed **strictly at client UI presentation boundaries** (Flutter app and Admin Web console).

---

## Rationale & Anti-Patterns

- Core backend database logic must NEVER depend on custom Bikram Sambat date calculations to avoid leap year / month length edge-case bugs in SQL queries.
