# GuffSuff Third-Party Open Source License Audit

> **Document Status**: Phase 3 Development Platform Baseline  
> **Audited Date**: 2026-08-05

---

## 1. License Policy & Classification Rules

- **Approved Permissive Licenses**: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC.
- **Copyleft / Restricted Licenses**: GPL-2.0, GPL-3.0, AGPL-3.0, LGPL-2.1, LGPL-3.0 (Prohibited in backend core services without explicit legal review).
- **Source-Available / Custom Licenses**: SSPL, BSLA, BSL (Strictly flagged and evaluated before inclusion).
- **Unknown / Unlicensed**: Prohibited from production runtime boundaries.

---

## 2. Dependency License Inventory

| Component / Package  | License      | Category   | Status   | Notes                 |
| :------------------- | :----------- | :--------- | :------- | :-------------------- |
| `turbo`              | MIT          | Permissive | Approved | Monorepo orchestrator |
| `typescript`         | Apache-2.0   | Permissive | Approved | Compiler              |
| `zod`                | MIT          | Permissive | Approved | Schema validation     |
| `pino`               | MIT          | Permissive | Approved | Logger                |
| `@opentelemetry/api` | Apache-2.0   | Permissive | Approved | Tracing API           |
| `pg`                 | MIT          | Permissive | Approved | PostgreSQL driver     |
| `bullmq`             | MIT          | Permissive | Approved | Queue framework       |
| `@aws-sdk/client-s3` | Apache-2.0   | Permissive | Approved | S3 client             |
| `@nestjs/core`       | MIT          | Permissive | Approved | Backend framework     |
| `socket.io`          | MIT          | Permissive | Approved | WebSocket server      |
| `next`               | MIT          | Permissive | Approved | Web framework         |
| `flutter_sdk`        | BSD-3-Clause | Permissive | Approved | Mobile UI framework   |

---

## 3. License Audit Summary

- **Total Direct Dependencies**: 12
- **Permissive (MIT / Apache-2.0 / BSD-3)**: 12 (100%)
- **Copyleft / AGPL / SSPL**: 0
- **Unknown / Custom**: 0
