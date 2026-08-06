# ADR-062: Provider-Neutral Mobile Cryptographic Boundary Architecture

- **Status**: Accepted
- **Date**: 2026-08-06
- **Authors**: Technical Lead / Antigravity Pair
- **Deciders**: Mobile & Security Architecture Committees

---

## Context & Decision

To isolate mobile application development from pending provider decisions (Track A direct messaging and Track B MLS group messaging), GuffSuff establishes a **provider-neutral mobile cryptographic boundary**. Native cryptographic backends connect to Flutter/Dart through opaque handles and typed byte-buffer transport. No production cryptographic backends are embedded until formal security and dependency release gates are passed.
