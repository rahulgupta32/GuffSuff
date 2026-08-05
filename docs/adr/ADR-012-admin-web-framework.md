# ADR-012: Admin Web Console Framework Selection

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

The administrative and Trust & Safety console (`apps/admin`) requires a responsive, highly secure web application supporting Role-Based Access Control (RBAC), multi-factor authentication (MFA), user report processing, and aggregate service health telemetry.

---

## Decision

We select **Next.js (TypeScript)** with React 18, Tailwind CSS / custom design tokens, and NextAuth / custom JWT MFA for `apps/admin`.

---

## Rationale

- Excellent server-side rendering (SSR) security defaults for administrative dashboards.
- Shares TypeScript types directly with `packages/contracts`.
- Easy integration of admin audit logging middleware.
