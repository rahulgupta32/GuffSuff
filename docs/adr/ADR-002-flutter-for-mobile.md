# ADR-002: Flutter for Mobile Application Development

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Mobile Architect, GuffSuff Lead Architecture Team
- **Decision Status**: Proposed

---

## Context

GuffSuff requires high-performance Android and iOS mobile applications supporting rich Devanagari typography, low-bandwidth data optimization, offline local persistence, and native cryptographic storage (Keychain and Keystore). Developing separate native codebases (Kotlin/Swift) increases engineering overhead for an initial MVP.

---

## Decision

We propose **Flutter with Dart** as the primary cross-platform mobile framework for GuffSuff.

### Key Architecture Components

- **State Management**: Riverpod (`flutter_riverpod`) for compile-safe, testable state management.
- **Navigation**: `go_router` for declarative routing and deep-link handling.
- **HTTP Client**: `dio` with custom interceptors for request correlation, automatic token refresh, and compressed payload handling.
- **Local Persistence Layer**: `drift` as the Dart ORM persistence and query abstraction layer over SQLite.
- **Database At-Rest Encryption**: **Drift itself does not provide database encryption.** At-rest encryption requires a separately evaluated SQLCipher-compatible SQLite implementation or another approved encrypted database driver.
- **Platform Key Integration**: Database encryption keys MUST be derived from platform hardware-backed secure storage (`flutter_secure_storage` interfacing with iOS Keychain and Android Keystore).
- **Localization**: ARB resource format supporting English and Devanagari Nepali (`np_NP`).

---

## Security & Database Boundary Constraints

- Android Keystore and Apple Keychain key derivation require explicit threat modeling in Phase 2.
- Database key recovery, key rotation, device migration, backup exclusion policy, screenshot suppression, memory exposure, and rooted/jailbroken device limitations remain subject to formal security review before approval.

---

## Alternatives Considered

- **React Native**: Rejected due to historic Devanagari text shaping inconsistencies across varying Android OEM text engines and bridge latency overhead for heavy binary payload encryption.
- **Native Kotlin / Swift**: Rejected for initial MVP phase due to doubled engineering effort across two separate codebases.

---

## Revisit Conditions

Re-evaluate if native platform APIs introduce insurmountable background sync or VoIP call limitations in post-MVP releases.
