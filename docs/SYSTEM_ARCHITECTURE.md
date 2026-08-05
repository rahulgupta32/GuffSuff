# GuffSuff System Architecture Specification

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Decision Status Vocabulary

All architectural components in this specification utilize the standardized GuffSuff decision-status vocabulary:

- **Proposed**: Initial architectural recommendation submitted for review.
- **Under evaluation**: Active technical prototyping or security evaluation underway.
- **Approved by product owner**: Explicitly accepted by `@rahulgupta32` with recorded date and evidence.
- **Approved by security review**: Accepted by Lead Security Reviewer following formal review.
- **Pending benchmark**: Awaiting performance, load, or latency testing under realistic conditions.
- **Rejected**: Explicitly evaluated and declined.
- **Superseded**: Replaced by a newer decision record.

---

## 2. Core Architecture Topology

GuffSuff is architected as a **Modular Monolith with Independently Deployable Microservice Entry Points** (`Proposed` - ADR-013).

```text
+-----------------------------------------------------------------------------------+
| APPLICATION LAYER                                                                 |
|  • apps/mobile (Flutter cross-platform Android/iOS app - Proposed)                 |
|  • apps/admin  (Next.js administrative web console - Proposed)                     |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| NETWORK & GATEWAY LAYER                                                           |
|  • WAF & TLS 1.3 Reverse Proxy / Load Balancer                                   |
+-----------------------------------------------------------------------------------+
                                         |
                     +-------------------+-------------------+
                     |                                       |
                     v                                       v
+-----------------------------------+   +-----------------------------------+
| REST API GATEWAY                  |   | REALTIME WEBSOCKET GATEWAY        |
|  • services/api (NestJS - Proposed)|   |  • services/realtime (Proposed)   |
|  • Auth, Profiles, Key Bundles    |   |  • Encrypted Envelope Routing     |
+-----------------------------------+   +-----------------------------------+
                     |                                       |
                     +-------------------+-------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| DATA & BACKGROUND LAYER                                                           |
|  • services/worker (BullMQ Background Queue - Proposed)                           |
|  • PostgreSQL (Durable System of Record - Baseline Deployment - Proposed)         |
|  • Redis Cluster (Ephemeral PubSub & Rate Limiting - Baseline - Proposed)         |
|  • S3 Object Store (Client-Side Encrypted Media Blobs - Proposed)                 |
+-----------------------------------------------------------------------------------+
```

---

## 3. Database & Container Deployment Rules

- **PostgreSQL & Redis Baselines**: Specified database versions represent initial deployment baselines. Deployments MUST enforce supported releases, security-patch policies, and prohibited use of floating container image tags (`latest`).
- **Mobile Local Storage**: Flutter client uses `drift` as persistence layer. At-rest encryption requires a separately evaluated SQLCipher-compatible SQLite driver with keys sourced from platform secure storage (Android Keystore / Apple Keychain).
