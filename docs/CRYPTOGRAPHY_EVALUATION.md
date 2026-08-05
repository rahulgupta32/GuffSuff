# GuffSuff Cryptographic Provider Evaluation Framework

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Evaluation Scope & 21-Point Criteria Matrix

We evaluate cryptographic candidate engines across 21 functional, security, operational, and licensing criteria:

1. **One-to-One Asynchronous Messaging**: Support for establishing asynchronous E2EE sessions when recipient is offline.
2. **One-to-One Multi-Device Fan-Out**: Capability to handle multiple registered physical devices per account cleanly.
3. **Private Group Messaging**: Efficiency of group session creation and payload distribution.
4. **Dynamic Group Membership Changes**: Performance when adding or removing group members.
5. **Encrypted Attachment Key Transport**: Support for transporting random AES-256 media keys securely within message envelopes.
6. **Out-of-Band Device Verification**: Fingerprint / Safety Number derivation for manual or QR-code identity verification.
7. **Key Change Notifications**: Real-time events when a contact changes identity keys (e.g. new phone purchase).
8. **Forward Secrecy (FS)**: Guarantee that compromise of long-term keys does not decrypt past session messages.
9. **Post-Compromise Security (PCS)**: Ability of ratcheting scheme to self-heal and regain secrecy after a temporary state compromise.
10. **Offline Recipient Support**: Prekey bundle architecture for asynchronous initial session setup.
11. **Server Compromise Resilience**: Zero plaintext exposure if backend infrastructure is fully breached.
12. **Client Endpoint Compromise Boundaries**: Isolation of compromised device sessions from non-compromised devices.
13. **Protocol Version Upgrade Path**: Graceful negotiation of protocol version upgrades without breaking active chats.
14. **Local Backup & Session Recovery**: Safe migration or restoration of local identity keys.
15. **Cross-Platform Mobile Support**: Availability of bindings for Flutter (Dart FFI), Android (C++/Rust/Java), and iOS (Swift/C++).
16. **Software Licensing Terms**: Compatibility of open-source or commercial license with GuffSuff deployment model.
17. **External Maintenance & Support**: Active upstream maintainer ecosystem and bug fix cadence.
18. **Third-Party Security Audit History**: Track record of independent, publicly disclosed cryptographic audits.
19. **Interoperability**: Standardized protocol specifications (e.g., IETF RFCs).
20. **Migration Risk**: Difficulty of migrating conversation state to future cryptographic specifications (e.g. Post-Quantum PQXDH).
21. **Implementation Complexity**: Engineering effort and vulnerability surface area introduced by native bindings.

---

## 2. Cryptographic Candidates Under Evaluation

### Candidate A: Signal Protocol (`libsignal-ffi` / `libsignal-client`)

- **Official Source**: `https://github.com/signalapp/libsignal`
- **License**: AGPL-3.0 (Requires careful dual-licensing or separate process boundary evaluation for proprietary mobile apps).
- **Supported Languages**: Rust core with C/FFI bindings, Java/Kotlin, Swift.
- **Flutter Integration**: Requires Dart FFI bindings (`flutter_rust_bridge`) interfacing with compiled native `.so` / `.dylib` binaries.
- **Audit Evidence**: Extensive public independent audits (Cure53, NCC Group).
- **Evaluation Status**: **UNDER EVALUATION** (Primary candidate for 1-to-1 asynchronous E2EE).

### Candidate B: Messaging Layer Security (MLS / IETF RFC 9420)

- **Official Source**: OpenMLS (`https://github.com/openmls/openmls`) / Cisco MLS (`https://github.com/cisco/mbed-mls`)
- **License**: Apache-2.0 / MIT.
- **Supported Languages**: Rust core with C/FFI bindings.
- **Flutter Integration**: Requires Dart FFI bindings.
- **Audit Evidence**: Formally verified protocol logic (IETF standard RFC 9420); OpenMLS audited by Symbolic Software (2023).
- **Evaluation Status**: **UNDER EVALUATION** (Primary candidate for scalable group messaging).

### Candidate C: Hybrid Architecture (Signal for 1-to-1 + MLS for Groups)

- **Evaluation Status**: **UNDER EVALUATION** (Subject to independent cryptographic review in Phase 2).

---

## 3. Strict Cryptographic Prohibition Rules

- Developers MUST NOT create custom Double Ratchet, X3DH, PQXDH, MLS, AEAD, HKDF, signature, or key-derivation implementations.
- Source code copied from unofficial blogs, tutorials, or un-audited repositories is STRICTLY FORBIDDEN.
