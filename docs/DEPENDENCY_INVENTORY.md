# GuffSuff Dependency Inventory & Vulnerability Audit

> **Document Status**: Phase 3 Development Platform Baseline  
> **Audited Date**: 2026-08-05  
> **Total Monorepo Workspace Packages**: 18 (13 Shared Packages, 3 Service Entry Points, 2 Applications)

---

## 1. Workspace Monorepo Package Inventory (18 Total)

### Shared Internal Packages (13)

1. `@guffsuff/contracts`: Shared API DTOs and Zod schemas
2. `@guffsuff/crypto-adapter`: Cryptographic provider interface boundaries
3. `@guffsuff/database`: Kysely PostgreSQL query builder and pool manager
4. `@guffsuff/design-system`: Mobile and Web UI design tokens
5. `@guffsuff/errors`: Domain error hierarchy
6. `@guffsuff/id-generation`: UUIDv7 and secure random identifier generators
7. `@guffsuff/localization`: Nepali/English string catalogs and Devanagari formatters
8. `@guffsuff/logger`: Pino structured JSON logger with automatic PII masking
9. `@guffsuff/object-storage`: S3 path-style MinIO object storage client
10. `@guffsuff/observability`: OpenTelemetry tracing and metrics primitives
11. `@guffsuff/queue`: Redis BullMQ job queues with environment key prefixing
12. `@guffsuff/shared-config`: Fail-closed Zod environment configuration validation
13. `@guffsuff/test-utils`: Test runners and isolation utilities

### Service Applications (3)

14. `services/api`: NestJS HTTP REST backend entry point (`@guffsuff/api`)
15. `services/realtime`: NestJS WebSocket gateway entry point (`@guffsuff/realtime`)
16. `services/worker`: Node.js BullMQ queue worker entry point (`@guffsuff/worker`)

### Client Applications (2)

17. `apps/mobile`: Flutter 3.29 mobile application for Android and iOS
18. `apps/admin`: Next.js 15 App Router web administrative console (`@guffsuff/admin`)

---

## 2. Dependency Vulnerability Advisory Table

| Advisory ID             | Dependency            | Installed Version | Dependency Path                               | Severity | Affected Component  | Usage Context            | Exploit Preconditions                                        | Patched Version | Direct Remediation                | Temporary Mitigation                                     | Decision Owner | Expiration Date |
| :---------------------- | :-------------------- | :---------------- | :-------------------------------------------- | :------- | :------------------ | :----------------------- | :----------------------------------------------------------- | :-------------- | :-------------------------------- | :------------------------------------------------------- | :------------- | :-------------- |
| **GHSA-r28c-9q8g-f849** | `postcss`             | `8.4.31`          | `apps/admin -> next -> postcss`               | High     | `apps/admin`        | Build-time CSS bundling  | Attacker-controlled untrusted CSS input parsed at build time | `8.5.10`        | Upgrade Next.js to 15.2+          | CSS input controlled strictly by repository committers   | Security Lead  | 2026-09-30      |
| **GHSA-qx2v-qp2m-jg93** | `postcss`             | `8.4.31`          | `apps/admin -> next -> postcss`               | High     | `apps/admin`        | Build-time CSS bundling  | Crafted custom CSS comment parsing during build              | `8.5.10`        | Upgrade Next.js to 15.2+          | Strict CI build sandbox                                  | Security Lead  | 2026-09-30      |
| **GHSA-fxqj-rqcc-2cmp** | `postcss`             | `8.4.31`          | `apps/admin -> next -> postcss`               | Moderate | `apps/admin`        | Development build time   | Unsanitized CSS input                                        | `8.5.23`        | Root `package.json` pnpm override | Override pinned to `8.5.23`                              | DevSecOps      | 2026-09-30      |
| **GHSA-8988-4f7v-96qf** | `@opentelemetry/core` | `1.30.1`          | `services/api -> @opentelemetry/core`         | Moderate | `services/*`        | Observability tracing    | Malicious HTTP W3C baggage header payload                    | `2.8.0`         | Root `package.json` pnpm override | W3C baggage header disabled on public REST endpoints     | Backend Lead   | 2026-09-30      |
| **GHSA-c2qf-rxjj-454g** | `body-parser`         | `1.20.2`          | `services/api -> @nestjs/core -> body-parser` | Moderate | `services/api`      | API request body parsing | Unbounded JSON body payload                                  | `1.20.3`        | Upgrade NestJS subdependency      | Express payload size limit enforced at 100kb             | Backend Lead   | 2026-09-30      |
| **GHSA-76p3-8jx3-hpfq** | `ws`                  | `8.17.1`          | `services/realtime -> socket.io -> ws`        | Moderate | `services/realtime` | WebSocket transport      | Unauthenticated client frame flood                           | `8.18.0`        | Upgrade Socket.IO                 | Connection rate limiting & authentication handshake gate | Realtime Lead  | 2026-09-30      |
| **GHSA-35jh-r3h4-6jhm** | `cookie`              | `0.6.0`           | `apps/admin -> next -> cookie`                | Low      | `apps/admin`        | Admin session cookies    | Malicious cookie name character injection                    | `0.7.0`         | Upgrade Next.js in Phase 4        | Strict cookie name allowlist                             | Frontend Lead  | 2026-09-30      |
