# Cryptographic Candidate Comparison Matrix & Reassessment Baseline

> **Document Status**: Active Candidate Reassessment (Post-Incident Baseline Re-evaluation)

---

## 1. Candidate Baseline Reassessment Matrix

| Candidate & Version | Classification & Status | Maven / Package Availability | Protocol API Features | Security / Maintenance | Swift / FFI Route |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Candidate A (`libsignal` `v0.60.0`)** | `Historical comparison baseline — not proposed for production integration` | Published on Maven Central (`org.signal:libsignal-android:0.60.0`, `aar`) | Double Ratchet, X3DH, Sealed Sender | AGPL-3.0, unmaintained upstream for 3rd-party use | Rust C-FFI / JNI / Swift bridge |
| **Candidate A (`libsignal` `v0.99.4`)** | `UNDER EVALUATION` (Requires custom build / private packaging) | Source build only (No public Maven Central artifacts) | PQX3DH, Double Ratchet, Post-Quantum ML-KEM-768 | AGPL-3.0, actively maintained by Signal, 3rd-party unsupported | Rust C-FFI / Swift SPM |
| **Candidate B (OpenMLS `openmls-v0.8.1`)** | `Proposed Spike Evaluation Candidate` | Published on Crates.io (`openmls = "0.8.1"`) | RFC 9420 TreeKEM Group Messaging | MIT / Apache-2.0, actively maintained open-source standard | Rust C-FFI / UniFFI |

---

## 2. Recommendation & Selection Rationale

- **Direct Messaging (1:1)**: `libsignal` `v0.60.0` serves as a historical baseline. Any future production evaluation requires legal review of AGPL-3.0 and custom source build pipelines for newer versions.
- **Group Messaging (Multi-Party)**: OpenMLS `openmls-v0.8.1` is the selected active candidate for group messaging due to full RFC 9420 compliance, permissive licensing, and public package availability.
