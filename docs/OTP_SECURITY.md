# GuffSuff OTP Security & Authentication Engine Specification

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: Sparrow SMS is one candidate under evaluation. Vendor selection requires satisfying all provider security requirements detailed below.

---

## 1. OTP Provider Security Evaluation Framework

Any SMS OTP vendor integrated with GuffSuff MUST satisfy the following criteria:
- Direct local telecom routing coverage in Nepal (+977 Ncell & NTC networks).
- Support for API authentication via TLS 1.3 with IP allowlisting and HMAC request signatures.
- Webhook signature verification for delivery receipts (`ACK`).
- SLA guaranteeing > 99.5% delivery within 30 seconds.
- Built-in SMS-pumping and toll-fraud rate limiting controls.
- Strict data-processing agreement prohibiting third-party SMS text retention > 24 hours.

---

## 2. Technical OTP Engine Constraints

1. **E.164 Normalization**: Strict validation and E.164 formatting (`+97798XXXXXXXX`) before dispatch.
2. **Secure Random Generation**: OTPs generated using CSPRNG (`crypto.randomInt(100000, 999999)`).
3. **Argon2id Hash Storage**: Raw OTPs are NEVER stored in Redis or databases. Only `Argon2id(OTP + Salt)` is cached with 5-minute TTL.
4. **Rate Limiting & Throttling**:
   - Max 1 OTP request per phone number per 60 seconds.
   - Max 3 OTP requests per phone number per 15 minutes.
   - Max 3 verification attempts per OTP before hard invalidation.
5. **Generic Enumeration Protections**: API responses return identical `{"status": "SENT"}` payloads regardless of whether a phone number is registered or unregistered.
6. **No Static OTPs in Production**: Hardcoded or bypass OTP codes (`123456`) are STRICTLY PROHIBITED in staging and production (`GATE-04`).

---

## 3. Alternative Authentication Trade-Off Analysis

| Mechanism | Security Strength | Nepal Usability | SIM-Swap Resilience | Recovery Overhead | Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SMS OTP** | Medium | High (Universal 2G/4G SMS) | Low (Vulnerable to SIM swap) | Low | Primary onboarding channel for MVP. |
| **Registration PIN** | High | High (In-app 6-digit PIN) | High (Prevents SIM-swap login) | Medium | Mandatory secondary lock for re-registration (`AUTH-003`). |
| **Passkeys / WebAuthn** | Very High | Low (Requires modern OS/hardware) | Immune | High | Under evaluation for Admin Console and post-MVP mobile. |
| **Voice Call OTP** | Medium | Medium | Low | Medium | Secondary fallback channel for failed SMS delivery. |
