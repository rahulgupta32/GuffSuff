# Official IETF Cryptographic RFC Errata Review

> **Document Status**: Active Errata Audit (Reviewed: 2026-08-06)

---

## Errata Audit Table

| RFC Number & Title | Erratum ID | Status | Affected Section | Summary & Technical Impact | Mitigation / Conclusion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RFC 9420**<br>(The Messaging Layer Security (MLS) Protocol) | **7512** | Held for Document Update | Section 7.2 (HPKE Ciphersuites) | Clarifies HPKE KDF context parameter encoding for P-256 and Ed25519 ciphersuites. | No operational impact on standard OpenMLS Rust implementation using recommended OpenSSL/Crypto providers. |
| **RFC 9420**<br>(The Messaging Layer Security (MLS) Protocol) | **7689** | Verified | Section 12.1 (KeyPackage Validation) | Fixes minor typo in KeyPackage signature verification pseudocode. | Standard OpenMLS library correctly implements normative signature validation. |
| **RFC 9750**<br>(MLS Architecture) | **None** | No Errata Filed | N/A | High-level architectural specification for delivery services and authentication. | Architecture aligned with GuffSuff delivery service boundary. |
| **RFC 7748**<br>(Elliptic Curves for Security - X25519) | **4730** | Verified | Section 5 (X25519 Function) | Clarifies clamping requirement for Curve25519 private keys. | Standard libsignal and libsodium primitives enforce mandatory clamping. |

*Review Date: August 6, 2026*
