# Phase 6 Cryptographic Decision Package

> **Document Status**: Reassessed Decision Package (Post-Incident Verification Reset)

---

## 1. Executive Summary & Production Gate Status

- **Production Cryptographic Implementation**: `NOT AUTHORIZED`
- **Candidate Evaluation Status**: All native build and execution gates reset to `NOT EXECUTED` or `BLOCKED`.
- **`libsignal` `v0.60.0` Classification**: `Historical comparison baseline — not proposed for production integration`.
- **OpenMLS `openmls-v0.8.1` Classification**: `Proposed Spike Evaluation Candidate` (RFC 9420 compliant).

---

## 2. Decision Matrix

| Evaluation Dimension | Candidate A (`libsignal`) | Candidate B (OpenMLS) | Mandatory Production Gate |
| :--- | :--- | :--- | :--- |
| **Protocol Compatibility** | 1:1 Double Ratchet / X3DH | Multi-party RFC 9420 TreeKEM | Must support both 1:1 and group messaging |
| **License Compliance** | AGPL-3.0 Copyleft | MIT / Apache-2.0 Permissive | Requires legal counsel review approval |
| **Artifact Distribution** | Maven Central (`0.60.0` historical) / Source build | Crates.io (`openmls-v0.8.1`) | Reproducible build required |
| **External Security Audit** | Pending third-party audit | Pending third-party audit | Mandatory audit gate before production release |
