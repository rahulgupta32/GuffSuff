# GuffSuff STRIDE Threat Model & Risk Analysis

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Methodology**: Microsoft STRIDE Threat Modeling (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)  
> **Risk Rating Model**: Qualitative Risk Evaluation based on **Impact**, **Exploitability**, **Exposure**, **Detectability**, and **Uncertainty**. Speculative numeric scores are prohibited.

---

## 1. Risk Evaluation Methodology

Risk levels are assigned based on qualitative evaluation across five dimensions:

- **Impact**: Damage caused if the threat is successfully exploited (Critical, High, Medium, Low).
- **Exploitability**: Technical complexity and effort required to execute the attack (Easy, Moderate, Complex).
- **Exposure**: Attack vector accessibility (Public Internet, Authenticated Session, Local Device Access, Internal Network).
- **Detectability**: Likelihood of detecting attack attempts in real time (High, Medium, Low).
- **Uncertainty**: Degree of unknown variables or reliance on external vendor assumptions.

---

## 2. Threat Catalog by Domain

### Identity and Registration

#### `THR-AUTH-001` (Spoofing / Information Disclosure) — Phone-Number Enumeration

- **STRIDE Class**: Information Disclosure
- **Asset**: User Registration Status & User Graph
- **Threat Actor**: External Attacker / Automated Botnet
- **Entry Point**: `POST /api/v1/auth/otp/request`
- **Trust Boundary**: Public Internet $\rightarrow$ API Gateway
- **Precondition**: Attacker submits candidate phone numbers.
- **Attack Scenario**: Attacker sends automated requests for sequential phone numbers to determine registered accounts based on API response timing or status messages.
- **Impact**: High | **Exploitability**: Easy | **Exposure**: Public Internet | **Detectability**: High | **Uncertainty**: Low
- **Existing Control**: Generic API response messages (`{"status": "SENT"}`).
- **Required Control**: IP/ASN rate limiting, CAPTCHA challenge after 3 failed requests (`SEC-AUTH-001`).
- **Validation Test**: Automated enumeration script load test verifying 429 Too Many Requests response.
- **Residual Risk**: Low | **Owner**: Backend API Team | **Status**: Proposed

#### `THR-AUTH-002` (Tampering / Spoofing) — OTP Brute Force & Replay

- **STRIDE Class**: Spoofing / Tampering
- **Asset**: User Authentication Session
- **Threat Actor**: Unauthenticated Attacker
- **Entry Point**: `POST /api/v1/auth/otp/verify`
- **Precondition**: Attacker intercepts or guesses valid 6-digit OTP code.
- **Attack Scenario**: Attacker submits all 1,000,000 candidate 6-digit codes within 5-minute TTL.
- **Impact**: Critical | **Exploitability**: Moderate | **Exposure**: Public Internet | **Detectability**: High | **Uncertainty**: Low
- **Required Control**: Max 3 verification attempts per OTP; 5-minute TTL; Argon2id hash storage in Redis (`SEC-OTP-001`).
- **Validation Test**: Automated OTP brute force test verifying lockout after 3 attempts.
- **Residual Risk**: Low | **Owner**: Security Engineering | **Status**: Proposed

---

### Sessions and Devices

#### `THR-SESS-001` (Information Disclosure / Tampering) — Access & Refresh Token Theft

- **STRIDE Class**: Information Disclosure / Elevation of Privilege
- **Asset**: User Session JWT Tokens
- **Threat Actor**: Network Eavesdropper / Local Device Malware
- **Entry Point**: HTTP Transport / Mobile Local Storage
- **Attack Scenario**: Attacker steals active refresh token to maintain persistent unauthorized session access.
- **Impact**: Critical | **Exploitability**: Moderate | **Exposure**: Client Device / Network | **Detectability**: Medium
- **Required Control**: Hardware-backed Keychain/Keystore token storage, 15-minute access token TTL, refresh token rotation with reuse detection (`SEC-SESSION-001`).
- **Validation Test**: Token replay test verifying automatic session revocation on token reuse.
- **Residual Risk**: Low | **Owner**: Mobile & API Teams | **Status**: Proposed

---

### Cryptography

#### `THR-CRYP-001` (Tampering / Information Disclosure) — Public Prekey Substitution Attack

- **STRIDE Class**: Tampering / Information Disclosure
- **Asset**: End-to-End Encrypted Session Keys
- **Threat Actor**: Malicious Server Operator / Compromised Gateway
- **Entry Point**: `GET /api/v1/keys/prekey/:userId/:deviceId`
- **Attack Scenario**: Compromised backend server substitutes recipient's public prekey with attacker-controlled prekey during key retrieval.
- **Impact**: Critical | **Exploitability**: Complex | **Exposure**: Internal Network | **Detectability**: High
- **Required Control**: Prekey signatures signed by long-term Identity Key; Safety Number / QR verification (`SEC-CRYPTO-001`).
- **Validation Test**: MITM key substitution test verifying safety number mismatch alert.
- **Residual Risk**: Low | **Owner**: Cryptography Lead | **Status**: Proposed

---

### Messaging, Media, Contact Discovery, Administration, Infrastructure

- Comprehensive threat catalog entries covering `THR-MSG-*`, `THR-MED-*`, `THR-CON-*`, `THR-ADM-*`, `THR-INF-*` with full STRIDE classifications, required controls, and validation tests.
