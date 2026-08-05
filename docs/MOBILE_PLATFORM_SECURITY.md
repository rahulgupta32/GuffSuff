# GuffSuff Mobile Platform Security Specification (Android & iOS)

> **Document Status**: Phase 5 Security Architecture Baseline  
> **Citations**: OWASP MASVS v2.0.0, Android Security Best Practices, Apple iOS Security Architecture

---

## 1. Storage & Key Protection Controls

- **Hardware-Backed Master Key Protection**: Master database encryption keys and access credentials MUST be stored in platform hardware enclaves via `flutter_secure_storage` (iOS Keychain with Secure Enclave hardware protection / Android KeyStore with StrongBox / TEE). **Neither Secure Enclave nor Android KeyStore directly stores arbitrary protocol state.**
- **Database At-Rest Encryption**: All protocol session state, prekeys, ratchets, and messages MUST be stored inside local SQLite databases encrypted using SQLCipher (`ADR-002`, `ADR-010`). Master SQLCipher keys are protected by KeyStore/Keychain.
- **Backup Exclusion**: Local SQLite database files and secure storage keys MUST be explicitly excluded from OS cloud backups (`ALLOW_BACKUP=false` in Android Manifest, `NSURLIsExcludedFromBackupKey` on iOS).

---

## 2. Secure Storage Classification Matrix

| Item / Value Name | Confidentiality | Required Device Lock State | Backup Eligibility | Migration Behavior | Biometric Requirement | Invalidation Behavior | Deletion Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Access Token** | High | First Unlock | Excluded (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Device Only | Optional | Cleared on Logout | Purged on Revocation |
| **Refresh Token** | Critical | First Unlock | Excluded (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Device Only | Optional | Invalidated on Reuse | Purged on Logout |
| **Device Identifier** | Medium | Unlocked | Excluded (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Device Only | None | Permanent per device | Purged on Account Reset |
| **Device Private Key Placeholder** | Critical | First Unlock | Excluded (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Device Only | Optional | Hardware Locked | Purged on Revocation |
| **Local Database Key (SQLCipher)** | Critical | First Unlock | Excluded (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Device Only | Optional | Lockscreen Reset Invalidates | Purged on Reset |
| **Registration-Lock State** | High | Unlocked | Excluded (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Device Only | None | Failed Attempts Lock | Purged on Reset |
| **Biometric Preference** | Low | Unlocked | Excluded (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Device Only | None | Reset on OS Change | Local Reset |
| **Environment Config (Non-Secret)** | Public | Standard SharedPreferences / NSUserDefaults | Eligible | Allowed | None | None | App Uninstall |

### iOS Keychain Accessibility Evaluation
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: Enforced for Access Token, Refresh Token, Device Private Key Placeholder, and Local Database Key. Excludes items from iTunes/iCloud backups and prevents cross-device migration.

### Android Keystore & StrongBox Controls
- Hardware-backed Keystore with Master Key `AES256_GCM`.
- `useStrongBox = true` enabled on supported hardware (Pixel 3+, Samsung Knox devices).
- `android:allowBackup="false"` enforced in `AndroidManifest.xml`.

---

## 3. Platform Hardening & Application Safeguards

- **Screen Snapshot Protection**: Enable `FLAG_SECURE` on Android and obscure window preview during app switcher transitions on iOS.
- **Notification Privacy**: System push notifications convey zero message plaintext or sender names (`SEC-MSG-001`).
- **Clipboard Controls**: Sensitive keys or seed phrases MUST NOT be written to global system clipboard.
- **Deep-Link Validation**: Enforce strict domain origin checks on `guffsuff://` deep links and App Links / Universal Links.
- **Exported Component Restrictions**: Android activities and services MUST set `android:exported="false"` unless explicitly required.
- **Root & Jailbreak Posture**: Perform non-blocking root/jailbreak detection to display security warning banners without blocking accessibility tools.
