# Cryptographic Candidate Machine-Verified Version Pinning Specification

> **Document Status**: Machine-Verified References (Derived via Git remote & Maven/Crates.io APIs: 2026-08-06)

---

## Candidate A: `libsignal` (`libsignal-protocol-rs`)

- **Repository**: `https://github.com/signalapp/libsignal.git`
- **Verified Git Tag**: `v0.60.0`
- **Peeled Commit SHA**: `1b82e53c2be56f7ab0aef3650033f8fc4d584517`
- **Annotated Tag SHA**: `aedc91b3d4b712769cb0bf760b7717540e444c3d`
- **Official Java/Client Maven Coordinate**: `org.signal:libsignal-client:0.60.0` (Packaging: `jar`)
- **Official Android Maven Coordinate**: `org.signal:libsignal-android:0.60.0` (Packaging: `aar`)
- **Cargo Crate Dependency**: `libsignal-protocol-rs = "0.60.0"`
- **Commit Author Date**: October 23, 2024
- **Commit Committer Date**: October 23, 2024
- **GitHub Release Publication Date**: October 23, 2024 (21:57:38Z)
- **Maven Central Publication Timestamp**: October 23, 2024 (22:11:10 UTC)
- **License at Commit**: AGPL-3.0
- **Supported Platform APIs**: Rust C-FFI, Java JNI (`org.signal.libsignal`), Swift C-bridge
- **Retrieval Date**: August 6, 2026

---

## Candidate B: OpenMLS (`openmls`)

- **Repository**: `https://github.com/openmls/openmls.git`
- **Verified Git Tag**: `openmls-v0.8.1`
- **Peeled Commit SHA**: `47dbedecad0c1fd8eb5368d582250ebfcc1e1ce6`
- **Cargo Crate Versions**: `openmls = "0.8.1"`, `openmls_traits = "0.4.1"`, `openmls_rust_crypto = "0.4.1"`
- **Commit Author Date**: February 13, 2026
- **Commit Committer Date**: February 13, 2026
- **Annotated Tag Creation Date**: February 13, 2026
- **GitHub Release Publication Date**: February 13, 2026 (16:11:07Z)
- **Crates.io Publication Date**: February 13, 2026 (16:06:12Z)
- **Version Justification**: Upgraded from unmaintained `0.5.x` to maintained `0.8.1` (RFC 9420 compliant, security patches applied).
- **License at Commit**: MIT / Apache-2.0
- **Supported Rust Toolchain**: Rust 1.82.0+
- **Retrieval Date**: August 6, 2026
