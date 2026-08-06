# Cryptographic Compatibility Spike Acceptance Criteria & Status

> **Document Status**: Active Spike Verification Criteria

---

## 1. Executive Summary & Toolchain Status

- **Toolchain Installation Status**: `PARTIAL — Rust/Cargo, cargo-deny, and Miri host toolchains installed and verified; JDK, Android SDK/NDK, adb, emulator, Flutter, Dart, and iOS cross-compilation remain NOT INSTALLED / BLOCKED.`
- **Built-Artifact SBOM Status**: `PARTIAL — source-manifest dependency SBOMs generated and schema-validated; no native or mobile built-artifact SBOM exists because no candidate build has executed.`
- **OpenMLS Vectors Status**: `PARTIAL — 23 of 25 official vector suites mapped to executed tests and PASSED; 2 suites remain NOT EXECUTED (overall status PARTIAL per execution-map.json).`
- **OpenMLS Real State-Test Status**: `PASSED — 34-point group lifecycle and state persistence harness executed with zero failures.`
- **Cargo Deny Security Audit**: `FAILED — Audit flagged RUSTSEC-2024-0370 (unmaintained proc-macro-error2 dependency) and unallowed copyleft licenses in the transitive tree.`
- **Miri Memory Safety**: `PARTIAL — State serialization unit test PASSED (0.36s); full protocol harness BLOCKED due to unsupported Windows SystemTime FFI call in OpenMLS KeyPackage Lifetime creation.`
- **Direct-Message Candidate Conclusion**: `libsignal remains a direct-message evaluation candidate. No technical recommendation can be made until native builds, upstream tests, persistence tests, licensing review, and mobile bridge tests complete.`
- **Group Candidate Conclusion**: `OpenMLS remains a group key-agreement evaluation candidate. No technical recommendation can be made until upstream tests, state-persistence tests, Android/iOS builds, bridge tests, and external review complete.`
- **Protocol Terminology Standard**: `libsignal secure-messaging protocol interfaces exposed by the selected version`.

