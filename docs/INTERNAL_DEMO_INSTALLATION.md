# GuffSuff Internal Mobile Demo Installation Guide

## Build & Release Metadata

- **Application Name**: GuffSuff Internal Mobile Demo
- **Package Name**: `com.guffsuff.mobile`
- **Target OS**: Android 8.0+ (API Level 26+)
- **APK Filename**: `guffsuff-internal-demo.apk`
- **APK SHA-256**: `559601416FD123D78EAF4C2DBDADF6BA03188ACDFEE6835318F66183754E4A34`
- **APK Size**: `53,647,431 bytes` (~51.2 MB)
- **Branch**: `feature/internal-demo-mobile-app`
- **Commit SHA**: `0d231685`

---

## Security & Operational Scope

> [!IMPORTANT]
> **INTERNAL DEMONSTRATION ONLY**
> This build is provided solely for internal user interface, onboarding, and staging connectivity demonstration.
>
> - **Secure Message Transmission**: **DISABLED** (Fail-closed `UnavailableCryptoProvider` baseline).
> - **Production Cryptography**: **NOT AUTHORIZED** (Zero production cryptographic providers integrated).
> - **Plaintext Fallback**: **PROHIBITED** (Zero fallback to unencrypted messaging).
> - **OTP Mode**: Connects to staging API or falls back to **DEVELOPMENT OTP MODE** (Code: `123456`).

---

## Installation Steps (Physical Android Phone & Emulator)

### 1. Download & Transfer APK

Download `guffsuff-internal-demo.apk` from the build artifacts or transfer via USB / ADB to your physical Android device.

### 2. Enable Installation from Unknown Sources (Device Specific)

On your Android phone:

1. Open **Settings** -> **Apps** -> **Special App Access** -> **Install Unknown Apps**.
2. Select the file manager or browser used to open the APK (e.g., Files by Google or Chrome).
3. Toggle **Allow from this source**.

### 3. Install the APK

Open `guffsuff-internal-demo.apk` using your device file manager and tap **Install**.

Via ADB (Command Line):

```bash
adb install -r guffsuff-internal-demo.apk
adb shell am start -n com.guffsuff.mobile/.MainActivity
```

---

## Testing & Demonstration Walkthrough

1. **Welcome & Privacy Intro**: Tap **Get Started** to view the zero-knowledge privacy overview.
2. **Phone Number Entry**: Select country (default **Nepal `+977`**) and enter phone number (e.g. `9800000000`).
3. **OTP Verification**: Enter 6-digit OTP. When offline or on local development backend, use **`123456`**.
4. **Profile Setup**: Set display name, username, and status bio.
5. **Home & Chat List**: Navigate between Chats, People, Updates, and Settings.
6. **Disabled Composer Demonstration**: Open any chat to observe rendered chat UI and verify that message sending is strictly disabled with the notice:
   > _"Secure messaging is not available in this build."_
7. **Internal Diagnostics**: Navigate to **Settings** -> **Internal Diagnostics** to inspect API environment, WebSocket status, device ID, and crypto boundary state (`UNAVAILABLE`).
