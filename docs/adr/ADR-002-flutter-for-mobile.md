# ADR-002: Flutter for Mobile Application Development

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff requires high-performance Android and iOS mobile applications supporting rich Devanagari typography, low-bandwidth data optimization, offline local encrypted persistence, and native cryptographic storage (Keychain and Keystore). Developing separate native codebases (Kotlin/Swift) increases engineering overhead for an initial MVP.

---

## Decision

We select **Flutter with Dart** as the primary cross-platform mobile framework for GuffSuff.

### Key Architecture Components
- **State Management**: Riverpod (`flutter_riverpod`) for compile-safe, testable state management.
- **Navigation**: `go_router` for declarative routing and deep-link handling.
- **HTTP Client**: `dio` with custom interceptors for request correlation, automatic token refresh, and compressed payload handling.
- **Local Persistence**: `drift` (SQLite wrapper with optional SQLCipher encryption) for offline messaging and local device search.
- **Secure Key Storage**: `flutter_secure_storage` interfacing with iOS Keychain and Android Keystore.
- **Localization**: ARB resource format supporting English and Devanagari Nepali (`np_NP`).

---

## Alternatives Considered

- **React Native**: Rejected due to historic Devanagari text shaping inconsistencies across varying Android OEM text engines and bridge latency overhead for heavy binary payload encryption.
- **Native Kotlin / Swift**: Rejected for initial MVP phase due to doubled engineering effort across two separate codebases.

---

## Consequences & Implications

- **Pros**: Single shared codebase, consistent custom rendering engine for flawless Devanagari Matra display, high performance 60fps UI.
- **Cons**: Slightly larger initial binary footprint (approx. 15-20MB APK/IPA), requires FFI binding for native crypto libraries.
- **Security**: Must ensure local SQLite database is encrypted via SQLCipher and key material is stored exclusively in hardware-backed keystores.

---

## Revisit Conditions

Re-evaluate if native platform APIs introduce insurmountable background sync or VoIP call limitations in post-MVP releases.
