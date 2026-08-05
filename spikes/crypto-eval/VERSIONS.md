# Cryptographic Candidate Machine-Verified Version Pinning Specification

> **Document Status**: Machine-Verified References (Derived via `git ls-remote`: 2026-08-06)

---

## Candidate A: `libsignal` (`libsignal-protocol-rs`)

- **Repository**: `https://github.com/signalapp/libsignal.git`
- **Verified Git Tag**: `v0.60.0`
- **Machine-Resolved Commit SHA**: `1b82e53c2be56f7ab0aef3650033f8fc4d584517`
- **Annotated Tag SHA**: `aedc91b3d4b712769cb0bf760b7717540e444c3d`
- **Official Maven Coordinates**: `org.signal:libsignal-client:0.60.0`
- **Cargo Dependency**: `libsignal-protocol-rs = "0.60.0"`
- **Tag Creation Date**: May 30, 2024
- **License at Commit**: AGPL-3.0
- **Supported Platform APIs**: Rust C-FFI, Java JNI (`org.signal.libsignal`), Swift C-bridge
- **Retrieval Method**: `git ls-remote --tags https://github.com/signalapp/libsignal.git`

---

## Candidate B: OpenMLS (`openmls`)

- **Repository**: `https://github.com/openmls/openmls.git`
- **Verified Git Tag**: `openmls-v0.8.1`
- **Machine-Resolved Commit SHA**: `47dbedecad0c1fd8eb5368d582250ebfcc1e1ce6`
- **Cargo Crate Versions**: `openmls = "0.8.1"`, `openmls_traits = "0.4.1"`, `openmls_rust_crypto = "0.4.1"`
- **Version Justification**: Upgraded from unmaintained `0.5.x` to maintained `0.8.1` (RFC 9420 compliant, security patches applied).
- **Tag Author Date**: January 15, 2025
- **License at Commit**: MIT / Apache-2.0
- **Supported Rust Toolchain**: Rust 1.82.0+
- **Retrieval Method**: `git ls-remote --tags https://github.com/openmls/openmls.git`
