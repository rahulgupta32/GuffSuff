# GuffSuff Master Architectural Decision Log

> **Document Status**: Phase 3 Development Platform Baseline  
> **Repository**: `git@github.com:rahulgupta32/GuffSuff.git`

---

## Master ADR Index

| ADR ID      | Decision Title                      | Decision Status             | Phase Introduced | Related Component / Target |
| :---------- | :---------------------------------- | :-------------------------- | :--------------- | :------------------------- |
| **ADR-001** | Git Branching Strategy & Protection | `Approved by product owner` | Phase 1          | Repository Workflow        |
| **ADR-002** | Flutter for Cross-Platform Mobile   | `Proposed`                  | Phase 1          | `apps/mobile`              |
| **ADR-003** | TypeScript & NestJS for Backend     | `Approved by product owner` | Phase 1          | `services/*`               |
| **ADR-004** | PostgreSQL as System of Record      | `Proposed`                  | Phase 1          | Primary Database           |
| **ADR-005** | Redis Ephemeral Coordination        | `Proposed`                  | Phase 1          | Realtime PubSub / Cache    |
| **ADR-006** | S3 Encrypted Object Storage         | `Proposed`                  | Phase 1          | Media Storage              |
| **ADR-007** | Dual REST + WebSocket Architecture  | `Proposed`                  | Phase 1          | Transport Layer            |
| **ADR-008** | Monorepo Structure & Isolation      | `Proposed`                  | Phase 1          | Codebase Layout            |
| **ADR-009** | Device-Based Identity Architecture  | `Proposed`                  | Phase 1          | User Identity Model        |
| **ADR-010** | Local Device Message Search         | `Proposed`                  | Phase 1          | Mobile SQLite FTS5         |
| **ADR-011** | UTC Storage & Calendar Conversion   | `Proposed`                  | Phase 1          | Time & Localization        |
| **ADR-012** | Next.js Framework for Admin Console | `Proposed`                  | Phase 1          | `apps/admin`               |
| **ADR-013** | Modular Monolith Service Boundaries | `Proposed`                  | Phase 1          | Service Architecture       |
| **ADR-014** | BullMQ Background Job Processing    | `Proposed`                  | Phase 1          | Worker Queue               |
| **ADR-015** | OpenAPI Contract Generation         | `Proposed`                  | Phase 1          | API Schema Specs           |
| **ADR-016** | Cryptographic Provider Abstraction  | `Proposed`                  | Phase 2          | `packages/crypto-adapter`  |
| **ADR-017** | Hardware-Backed Key Storage         | `Proposed`                  | Phase 2          | Keychain / Keystore        |
| **ADR-018** | Ephemeral Access Tokens & Refresh   | `Proposed`                  | Phase 2          | JWT Auth Engine            |
| **ADR-019** | OTP Hashing & Redis TTL             | `Proposed`                  | Phase 2          | OTP Security               |
| **ADR-020** | Privacy Contact Discovery Staging   | `Proposed`                  | Phase 2          | Discovery Engine           |
| **ADR-021** | Encrypted Attachment Key Transfer   | `Proposed`                  | Phase 2          | Media Encryption           |
| **ADR-022** | Device Revocation & Key Purging     | `Proposed`                  | Phase 2          | Device Security            |
| **ADR-023** | Allowlist Structured JSON Logging   | `Proposed`                  | Phase 2          | Observability Stream       |
| **ADR-024** | Admin WebAuthn MFA & Four-Eyes      | `Proposed`                  | Phase 2          | Admin Privileges           |
| **ADR-025** | Incident Response Runbook Engine    | `Proposed`                  | Phase 2          | Incident Management        |
| **ADR-026** | Vulnerability Remediation SLAs      | `Proposed`                  | Phase 2          | Supply Chain               |
| **ADR-027** | Dependency Pinning & Supply Chain   | `Proposed`                  | Phase 2          | CI/CD Workflows            |
| **ADR-028** | Security Acceptance Release Gates   | `Proposed`                  | Phase 2          | Launch Readiness           |
| **ADR-029** | Mobile SQLite At-Rest Encryption    | `Proposed`                  | Phase 2          | Mobile Database            |
| **ADR-030** | Envelope Retention & Purge Policy   | `Under evaluation`          | Phase 2          | Data Retention             |
| **ADR-031** | Monorepo Build Tooling Strategy     | `Proposed`                  | Phase 3          | `pnpm` & `turbo`           |
| **ADR-032** | Runtime Schema Validation & Zod     | `Proposed`                  | Phase 3          | `packages/contracts`       |
| **ADR-033** | Database Access Layer (Kysely)      | `Proposed`                  | Phase 3          | `packages/database`        |
| **ADR-034** | Fail-Closed Config Validation       | `Proposed`                  | Phase 3          | Configuration Engine       |
| **ADR-035** | Local S3 Object Storage Emulator    | `Proposed`                  | Phase 3          | MinIO Emulator             |
| **ADR-036** | Privacy-Safe Observability          | `Proposed`                  | Phase 3          | OpenTelemetry / Pino       |
| **ADR-037** | Isolated Test Environment Strategy  | `Proposed`                  | Phase 3          | Test Automation            |
| **ADR-038** | Non-Root Base-Image Policy          | `Proposed`                  | Phase 3          | Docker Security            |
| **ADR-039** | Least-Privilege Pinned CI Strategy  | `Proposed`                  | Phase 3          | GitHub Actions             |
| **ADR-040** | Build Flavor Environment Isolation  | `Proposed`                  | Phase 3          | Mobile / Web Flavors       |
