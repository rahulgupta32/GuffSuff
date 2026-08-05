# Cryptographic Compatibility Spike Acceptance Criteria & Status

> **Document Status**: Active Spike Verification Criteria

---

## 1. Executive Summary & Toolchain Status

- **Toolchain Installation Status**: `PARTIAL — JDK 21 and Rust/Cargo installed and verified; Android NDK, Flutter, and macOS iOS toolchains remain missing/blocked.`
- **Built-Artifact SBOM Status**: `PARTIAL — source-manifest dependency SBOMs generated and schema-validated; no native or mobile built-artifact SBOM exists because no candidate build has executed.`
- **OpenMLS Vectors Status**: `NOT EXECUTED — upstream vector and interoperability fixture availability has not yet been verified from an executable exact-version checkout.`
- **OpenMLS Real State-Test Status**: `PARTIAL — native Rust state harness executed successfully, but actual OpenMLS group lifecycle and protocol-state persistence have not yet been exercised.`
- **Direct-Message Candidate Conclusion**: `libsignal remains a direct-message evaluation candidate. No technical recommendation can be made until native builds, upstream tests, persistence tests, licensing review, and mobile bridge tests complete.`
- **Group Candidate Conclusion**: `OpenMLS remains a group key-agreement evaluation candidate. No technical recommendation can be made until upstream tests, state-persistence tests, Android/iOS builds, bridge tests, and external review complete.`
- **Protocol Terminology Standard**: `libsignal secure-messaging protocol interfaces exposed by the selected version`.
