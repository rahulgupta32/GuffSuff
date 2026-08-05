# GuffSuff Technology Baselines & Version Reference

> **Document Status**: Phase 3 Development Platform Baseline  
> **Rule**: Floating versions (`latest`, `stable`, `*`) are strictly prohibited in production manifests.

---

## 1. Approved Runtime & Infrastructure Versions

| Technology / Component | Baseline Version               | Verification Source        | Maintenance Policy                   | Floating Version Status |
| :--------------------- | :----------------------------- | :------------------------- | :----------------------------------- | :---------------------- |
| **Node.js**            | `v24.15.0`                     | Active LTS Node.js Release | Bi-weekly security patch updates     | Prohibited              |
| **TypeScript**         | `5.7.3`                        | npm Registry               | Minor version upgrades upon testing  | Prohibited              |
| **pnpm**               | `11.20.0`                      | npm Global Package         | Corepack / pnpm pin                  | Prohibited              |
| **NestJS**             | `11.0.1`                       | NestJS Framework           | Major version LTS updates            | Prohibited              |
| **Next.js**            | `15.1.7`                       | Next.js Framework          | Active maintenance line              | Prohibited              |
| **Flutter**            | `3.29.2`                       | Flutter SDK Stable Channel | Stable release channel pins          | Prohibited              |
| **Dart**               | `3.7.0`                        | Dart SDK                   | SDK constraint pin in `pubspec.yaml` | Prohibited              |
| **PostgreSQL**         | `16.8-alpine3.21`              | Docker Official Image      | Pinned minor version patch           | Prohibited              |
| **Redis**              | `7.4.2-alpine3.21`             | Docker Official Image      | Pinned minor version patch           | Prohibited              |
| **MinIO**              | `RELEASE.2025-02-18T09-10-02Z` | Quay / Docker Hub          | Pinned release digest tag            | Prohibited              |
| **BullMQ**             | `5.41.6`                       | npm Registry               | Active queue maintenance             | Prohibited              |
| **Zod**                | `3.24.2`                       | npm Registry               | Active contract schema maintenance   | Prohibited              |
| **Pino**               | `9.6.0`                        | npm Registry               | Active logging maintenance           | Prohibited              |
| **OpenTelemetry SDK**  | `1.30.1`                       | npm Registry               | Active observability maintenance     | Prohibited              |
