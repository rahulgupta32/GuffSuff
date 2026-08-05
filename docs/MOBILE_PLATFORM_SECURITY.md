# GuffSuff Mobile Platform Security Specification (Android & iOS)

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Citations**: OWASP MASVS v2.0.0, Android Security Best Practices, Apple iOS Security Architecture

---

## 1. Storage & Key Protection Controls

- **Hardware-Backed Storage**: Private keys and SQLite encryption master keys MUST be stored in platform hardware enclaves via `flutter_secure_storage` (iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` / Android Keystore with `EncryptedSharedPreferences`).
- **Database At-Rest Encryption**: Local SQLite database MUST be encrypted using SQLCipher. Drift acts as the Dart ORM query layer over SQLCipher (`ADR-002`, `ADR-010`).
- **Backup Exclusion**: Local SQLite database files and secure storage keys MUST be explicitly excluded from OS cloud backups (`ALLOW_BACKUP=false` in Android Manifest, `NSURLIsExcludedFromBackupKey` on iOS).

---

## 2. Platform Hardening & Application Safeguards

- **Screen Snapshot Protection**: Enable `FLAG_SECURE` on Android and obscure window preview during app switcher transitions on iOS.
- **Notification Privacy**: System push notifications convey zero message plaintext or sender names (`SEC-MSG-001`).
- **Clipboard Controls**: Sensitive keys or seed phrases MUST NOT be written to global system clipboard.
- **Deep-Link Validation**: Enforce strict domain origin checks on `guffsuff://` deep links and App Links / Universal Links.
- **Exported Component Restrictions**: Android activities and services MUST set `android:exported="false"` unless explicitly required.
- **Root & Jailbreak Posture**: Perform non-blocking root/jailbreak detection to display security warning banners without blocking accessibility tools.
