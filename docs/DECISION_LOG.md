# GuffSuff Master Architectural Decision Log

> **Document Status**: Phase 6 Pre-Implementation Cryptographic Compatibility Spikes Baseline  
> **Repository**: `git@github.com:rahulgupta32/GuffSuff.git`
> 
> **ADR Allocation Note**: ADR-041 through ADR-050 were allocated to Phase 4 (Secure Identity, OTP, & Session Security). Consequently, Phase 5 (Opaque Encrypted Envelope Transport) was intentionally assigned ADR-051 through ADR-060 to maintain strict sequential uniqueness without rewriting repository history.

---

## Master ADR Index

| ADR ID      | Decision Title                      | Decision Status             | Phase Introduced | Related Component / Target |
| :---------- | :---------------------------------- | :-------------------------- | :--------------- | :------------------------- |
| **ADR-001** | Git Branching Strategy & Protection | `Approved by product owner` | Phase 1          | Repository Workflow        |
| **ADR-002** | Flutter for Cross-Platform Mobile   | `Approved by product owner` | Phase 1          | `apps/mobile`              |
| **ADR-003** | TypeScript & NestJS for Backend     | `Approved by product owner` | Phase 1          | `services/*`               |
| **ADR-004** | PostgreSQL as System of Record      | `Approved by product owner` | Phase 1          | Primary Database           |
| **ADR-005** | Redis Ephemeral Coordination        | `Approved by product owner` | Phase 1          | Realtime PubSub / Cache    |
| **ADR-006** | S3 Encrypted Object Storage         | `Proposed`                  | Phase 1          | Media Storage              |
| **ADR-007** | Dual REST + WebSocket Architecture  | `Approved by product owner` | Phase 1          | Transport Layer            |
| **ADR-008** | Monorepo Structure & Isolation      | `Approved by product owner` | Phase 1          | Codebase Layout            |
| **ADR-009** | Device-Based Identity Architecture  | `Approved by product owner` | Phase 1          | User Identity Model        |
| **ADR-010** | Local Device Message Search         | `Proposed`                  | Phase 1          | Mobile SQLite FTS5         |
| **ADR-011** | UTC Storage & Calendar Conversion   | `Approved by product owner` | Phase 1          | Time & Localization        |
| **ADR-012** | Next.js Framework for Admin Console | `Approved by product owner` | Phase 1          | `apps/admin`               |
| **ADR-013** | Modular Monolith Service Boundaries | `Approved by product owner` | Phase 1          | Service Architecture       |
| **ADR-014** | BullMQ Background Job Processing    | `Approved by product owner` | Phase 1          | Worker Queue               |
| **ADR-015** | OpenAPI Contract Generation         | `Approved by product owner` | Phase 1          | API Schema Specs           |
| **ADR-016** | Cryptographic Provider Abstraction  | `Approved by product owner` | Phase 2          | `packages/crypto-adapter`  |
| **ADR-017** | Hardware-Backed Key Storage         | `Approved by product owner` | Phase 2          | Keychain / Keystore        |
| **ADR-018** | Ephemeral Access Tokens & Refresh   | `Approved by product owner` | Phase 2          | JWT Auth Engine            |
| **ADR-019** | OTP Hashing & Redis TTL             | `Approved by product owner` | Phase 2          | OTP Security               |
| **ADR-020** | Privacy Contact Discovery Staging   | `Proposed`                  | Phase 2          | Discovery Engine           |
| **ADR-021** | Encrypted Attachment Key Transfer   | `Proposed`                  | Phase 2          | Media Encryption           |
| **ADR-022** | Device Revocation & Key Purging     | `Approved by product owner` | Phase 2          | Device Security            |
| **ADR-023** | Allowlist Structured JSON Logging   | `Approved by product owner` | Phase 2          | Observability Stream       |
| **ADR-024** | Admin WebAuthn MFA & Four-Eyes      | `Proposed`                  | Phase 2          | Admin Privileges           |
| **ADR-025** | Incident Response Runbook Engine    | `Approved by product owner` | Phase 2          | Incident Management        |
| **ADR-026** | Vulnerability Remediation SLAs      | `Approved by product owner` | Phase 2          | Supply Chain               |
| **ADR-027** | Dependency Pinning & Supply Chain   | `Approved by product owner` | Phase 2          | CI/CD Workflows            |
| **ADR-028** | Security Acceptance Release Gates   | `Approved by product owner` | Phase 2          | Launch Readiness           |
| **ADR-029** | Mobile SQLite At-Rest Encryption    | `Proposed`                  | Phase 2          | Mobile Database            |
| **ADR-030** | Envelope Retention & Purge Policy   | `Under evaluation`          | Phase 2          | Data Retention             |
| **ADR-031** | Monorepo Build Tooling Strategy     | `Approved by product owner` | Phase 3          | `pnpm` & `turbo`           |
| **ADR-032** | Runtime Schema Validation & Zod     | `Approved by product owner` | Phase 3          | `packages/contracts`       |
| **ADR-033** | Database Access Layer (Kysely)      | `Approved by product owner` | Phase 3          | `packages/database`        |
| **ADR-034** | Fail-Closed Config Validation       | `Approved by product owner` | Phase 3          | Configuration Engine       |
| **ADR-035** | Local S3 Object Storage Emulator    | `Approved by product owner` | Phase 3          | MinIO Emulator             |
| **ADR-036** | Privacy-Safe Observability          | `Approved by product owner` | Phase 3          | OpenTelemetry / Pino       |
| **ADR-037** | Isolated Test Environment Strategy  | `Approved by product owner` | Phase 3          | Test Automation            |
| **ADR-038** | Non-Root Base-Image Policy          | `Approved by product owner` | Phase 3          | Docker Security            |
| **ADR-039** | Least-Privilege Pinned CI Strategy  | `Approved by product owner` | Phase 3          | GitHub Actions             |
| **ADR-040** | Build Flavor Environment Isolation  | `Approved by product owner` | Phase 3          | Mobile / Web Flavors       |
| **ADR-041** | Phone Number Parsing & Normalization| `Approved by product owner` | Phase 4          | `PhoneNumberService`       |
| **ADR-042** | Keyed OTP Verifier & Challenge TTL  | `Approved by product owner` | Phase 4          | OTP Engine                 |
| **ADR-043** | Build-Isolated Development Simulator| `Approved by product owner` | Phase 4          | `@guffsuff/otp-simulator`  |
| **ADR-044** | Access & Refresh Token Architecture | `Approved by product owner` | Phase 4          | Session Engine             |
| **ADR-045** | Refresh Token Family Reuse Detection| `Approved by product owner` | Phase 4          | Session Security           |
| **ADR-046** | Username Regex & Cooldown          | `Approved by product owner` | Phase 4          | Account Domain             |
| **ADR-047** | Device Identity & Server Revocation | `Approved by product owner` | Phase 4          | Device Domain              |
| **ADR-048** | Privacy Setting Defaults           | `Approved by product owner` | Phase 4          | User Privacy               |
| **ADR-049** | Argon2id Registration Lock PIN     | `Approved by product owner` | Phase 4          | Lock Security              |
| **ADR-050** | Identity Security Event Projections | `Approved by product owner` | Phase 4          | Security Logging           |
| **ADR-051** | Opaque Encrypted Envelope Boundary  | `Approved by product owner` | Phase 5          | Transport Layer            |
| **ADR-052** | Message Idempotency Strategy        | `Approved by product owner` | Phase 5          | Idempotency Engine         |
| **ADR-053** | Per-Device Durable Delivery Model   | `Approved by product owner` | Phase 5          | Multi-Device Delivery      |
| **ADR-054** | Delivery Acknowledgement Semantics | `Approved by product owner` | Phase 5          | Monotonic Delivery State   |
| **ADR-055** | Offline Retry & Dead-Letter Policy  | `Approved by product owner` | Phase 5          | Worker Retries             |
| **ADR-056** | Push Wake-Up Privacy Model          | `Approved by product owner` | Phase 5          | Opaque Push Engine         |
| **ADR-057** | Message Transport Retention Config  | `Approved by product owner` | Phase 5          | Retention Engine           |
| **ADR-058** | Realtime Ordering & Deduplication   | `Approved by product owner` | Phase 5          | WebSocket Realtime Gateway |
| **ADR-059** | Mobile Local Transport Queue        | `Approved by product owner` | Phase 5          | Flutter Mobile Client      |
| **ADR-060** | Transport Test Mode Prohibition     | `Approved by product owner` | Phase 5          | Build Flavor Security      |
| **ADR-061** | Rejection of OpenMLS v0.8.1 Production Baseline | `Accepted (Rejection)` | Phase 6 | Cryptographic Architecture |

