# GuffSuff System Security Assumptions

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Purpose**: Document explicit technical and operational security assumptions underlying GuffSuff architecture.

---

## Technical Security Assumptions

| ID          | Security Assumption Description                                                                                       | Impact Area       | Business Acceptance Required?                                               | Related Threat / Requirement |
| :---------- | :-------------------------------------------------------------------------------------------------------------------- | :---------------- | :-------------------------------------------------------------------------- | :--------------------------- |
| **ASM-001** | Client physical devices (smartphones) may be compromised by malware, root/jailbreak, or physical access.              | Client Endpoints  | **Yes** (Risk of local device data exposure accepted)                       | `SEC-MOBILE-001`             |
| **ASM-002** | The backend server infrastructure may suffer unauthorized breach or subpoena attempt.                                 | Infrastructure    | No (Zero-knowledge architecture limits breach impact)                       | `SEC-DATA-001`               |
| **ASM-003** | Public network traffic (Wi-Fi, 4G, internet routers) may be actively intercepted or observed.                         | Transport Network | No (TLS 1.3 + E2EE payloads prevent interception)                           | `SEC-MSG-001`                |
| **ASM-004** | Push notification providers (FCM / APNs) can observe notification delivery metadata (timestamps, IP, device token).   | Metadata Privacy  | **Yes** (Push metadata visibility to Google/Apple accepted)                 | `SEC-MSG-001`                |
| **ASM-005** | Telecom providers (Ncell, NTC) can observe SMS OTP delivery metadata and raw SMS text.                                | Telecom Routing   | **Yes** (SMS OTP metadata visibility to telcos accepted)                    | `SEC-OTP-001`                |
| **ASM-006** | Mobile phone numbers in Nepal may be recycled by telcos and assigned to new subscribers over time.                    | Account Recovery  | **Yes** (Registration Lock PIN mitigates recycled SIM takeover)             | `SEC-AUTH-003`               |
| **ASM-007** | A secondary linked device registered under a user account may become compromised or malicious.                        | Multi-Device E2EE | No (Independent prekeys & device revocation mitigate)                       | `SEC-DEVICE-001`             |
| **ASM-008** | Server operators and database administrators MUST NOT possess message decryption capability.                          | Server Operations | No (E2EE architecture enforces zero-knowledge)                              | `SEC-CRYPTO-001`             |
| **ASM-009** | Mobile operating systems (Android/iOS) impose physical flash storage wear-leveling limits on secure deletion.         | Flash Storage     | **Yes** (Residual flash memory wear-leveling trace risk accepted)           | `SEC-MOBILE-001`             |
| **ASM-010** | Mobile RAM memory during active app usage may temporarily hold unencrypted message plaintext.                         | Device RAM        | **Yes** (Transient volatile RAM inspection risk on rooted devices accepted) | `SEC-MOBILE-001`             |
| **ASM-011** | Screen captures, external photography, or screen recordings cannot be 100% prevented on all mobile operating systems. | Content Leakage   | **Yes** (Recipient screenshot risk inherent to messaging)                   | `SEC-ABUSE-001`              |
| **ASM-012** | Platform resistance to global network traffic analysis and volume correlation is inherently limited.                  | Traffic Analysis  | **Yes** (Metadata minimization does not eliminate timing analysis)          | `SEC-PRIVACY-001`            |
| **ASM-013** | Metadata minimization reduces server-side metadata retention but does not eliminate operational routing metadata.     | Privacy Bounds    | **Yes** (Operational connection logs retained per policy)                   | `SEC-LOG-001`                |
| **ASM-014** | End-to-end cryptography cannot prevent a legitimate conversation recipient from leaking or reporting messages.        | Social Trust      | **Yes** (User reporting feature allows voluntarily submitted evidence)      | `SEC-ABUSE-001`              |
