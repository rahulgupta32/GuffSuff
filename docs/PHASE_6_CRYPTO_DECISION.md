# Phase 6 — Cryptographic Decision Package & Architecture Framework

> **Document Status**: Proposal & Evaluation Guidelines (Pre-Integration Phase 6)  
> **Production Status**: `BLOCKED` (Requires Legal Review & Independent Security Audit)

---

## 1. Executive Summary

This document defines the decision framework for evaluating production end-to-end encryption (E2EE) candidates for GuffSuff Phase 6. In accordance with project security policy, **no production cryptographic code or provider integration has been introduced during Phase 5 or Phase 6 spikes**.

---

## 2. Core Cryptographic Evaluation Matrix

| Topic ID | Cryptographic Concern | Candidate A (`libsignal`) | Candidate B (OpenMLS) | Status & Boundary |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **1:1 Asynchronous Session Setup** | `UNDER EVALUATION` | `NOT APPLICABLE` | X3DH / PQX3DH session setup. |
| **2** | **1:1 Multi-Device Management** | `UNDER EVALUATION` | `NOT APPLICABLE` | Pairwise sessions per device. |
| **3** | **Direct-Message Double Ratchet** | `UNDER EVALUATION` | `NOT APPLICABLE` | Forward Secrecy & Post-Compromise Security. |
| **4** | **Device Identity Verification** | `UNDER EVALUATION` | `UNDER EVALUATION` | QR / Safety number verification. |
| **5** | **Key-Change Warnings** | `UNDER EVALUATION` | `UNDER EVALUATION` | Untrusted identity key alert. |
| **6** | **Group Key Agreement** | `NOT APPLICABLE` | `UNDER EVALUATION` | TreeKEM (RFC 9420) key distribution. |
| **7** | **Group Membership Changes** | `NOT APPLICABLE` | `UNDER EVALUATION` | Immediate epoch increment on member add/remove. |
| **8** | **Attachment Key Transport** | `UNDER EVALUATION` | `UNDER EVALUATION` | Out-of-band AES-256-GCM media encryption. |
| **9** | **Protocol Versioning** | `PASSED` | `PASSED` | `protocolVersion: 2` with downgrade protection. |
| **10** | **Post-Quantum Roadmap** | `UNDER EVALUATION` | `UNDER EVALUATION` | PQX3DH / ML-KEM-768 migration path. |
| **11** | **Backup & Recovery** | `NOT EXECUTED` | `NOT EXECUTED` | Argon2id encrypted passphrase backup blob. |
| **12** | **Flutter FFI Integration** | `UNDER EVALUATION` | `UNDER EVALUATION` | Opaque native handles; raw keys forbidden in Dart String. |
| **13** | **Android Hardware KeyStore** | `PASSED` | `PASSED` | Master key in TEE/StrongBox; SQLite DB encrypted. |
| **14** | **iOS Keychain / Secure Enclave** | `PASSED` | `PASSED` | DB master key in Keychain; SQLite DB encrypted. |
| **15** | **Licensing & Open Source** | `BLOCKED` | `PASSED` | `libsignal` AGPL-3.0 copyleft requires legal review. |
| **16** | **External Maintainability** | `BLOCKED` | `PASSED` | `libsignal` external use explicitly unsupported upstream. |
| **17** | **Independent Audit Gate** | `BLOCKED` | `BLOCKED` | External audit required prior to production launch. |
| **18** | **Migration Safety** | `PASSED` | `PASSED` | Phase 5 opaque transport compatibility maintained. |
| **19** | **Downgrade Prevention** | `PASSED` | `PASSED` | Fail-closed policy on protocol version rollback. |
| **20** | **Cross-Platform Test Vectors** | `NOT EXECUTED` | `NOT EXECUTED` | Official KAT test vectors execution in progress. |
