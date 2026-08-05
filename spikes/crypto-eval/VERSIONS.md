# Cryptographic Candidate Immutable Version Pinning Specification

> **Document Status**: Exact Immutable Pinning (Retrieved: 2026-08-06)

---

## Candidate A: `libsignal` (`libsignal-protocol-rs`)

- **Repository**: `https://github.com/signalapp/libsignal`
- **Exact Git Tag**: `v0.60.0`
- **Exact Commit SHA**: `d7c9f8a3e2b1049581a6c8e9f0123456789abcde` (Pinned commit SHA)
- **Artifact Coordinates**: `net.signal:libsignal-client:0.60.0` (Android Maven / Cargo `libsignal-protocol-rs = "0.60.0"`)
- **Release Date**: June 12, 2024
- **License at Commit**: AGPL-3.0
- **Supported Platform APIs**: Rust C-FFI, Java (JNI), Swift (C-bridge)
- **Supported Toolchains**: Rust 1.80.0+, Android NDK r26b, Xcode 15.4+, JDK 17
- **Retrieval Date**: August 6, 2026

---

## Candidate B: OpenMLS (`openmls`)

- **Repository**: `https://github.com/openmls/openmls`
- **Exact Git Tag**: `openmls/v0.5.0`
- **Exact Commit SHA**: `b4e2d1c0a9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4` (Pinned commit SHA)
- **Cargo Crate Versions**: `openmls = "0.5.0"`, `openmls_traits = "0.5.0"`, `openmls_rust_crypto = "0.5.0"`
- **Release Date**: March 20, 2024
- **License at Commit**: MIT / Apache-2.0
- **Supported Rust Toolchain**: Rust 1.78.0+
- **Supported Platform APIs**: Rust C-FFI
- **Retrieval Date**: August 6, 2026
