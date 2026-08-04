# GuffSuff Threat Model & Risk Analysis

> **Status**: Initial Draft (Phase 0 Bootstrap)  
> **Framework**: STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)

---

## Primary Threat Matrix

| Threat Category | Asset | Vector / Entry Point | Required Mitigation |
| :--- | :--- | :--- | :--- |
| **Spoofing** | User Identity | SIM-Swap / OTP Brute Force | Cryptographic OTP limits, Registration PIN lock |
| **Information Disclosure** | Message Text | Server DB / Logs / Push Payloads | E2EE end-to-end payload encryption, zero server plaintext |
| **Denial of Service** | API / Realtime | Bot signups, WebSocket connection floods | Redis rate limiting, progressive IP/Device cooldowns |
| **Tampering** | Attachments | Malicious executable upload | Strict file-signature checks, AES-GCM tag verification |
