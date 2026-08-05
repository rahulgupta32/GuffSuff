# Isolated Cryptographic Evaluation Toolchain Specification

> **Document Status**: Isolated Toolchain Environment Standard

---

## 1. Local Toolchain Isolation Principles

1. **User-Local Directory**: All native toolchains (JDK, Android NDK, Rustup, Cargo) are targeted for isolated installation in `.tools/` within the repository root.
2. **Git Ignored**: `.tools/` is explicitly listed in `.gitignore` to prevent committing binary toolchain artifacts or local paths into source control.
3. **Zero Production Mutation**: Toolchains cannot modify production build pipelines, signing configs, or production application manifests.
4. **Checksum Verification**: All downloads must verify SHA-256 hashes against official upstream releases (Eclipse Temurin, Rustup.rs, Android Developer portal).

---

## 2. Toolchain Inventory & Specifications

- **JDK**: Eclipse Temurin 21.0.3+9 (LTS)
- **Android SDK / NDK**: Compile SDK 34, Min SDK 26, NDK 26.1.10909125
- **Rust Toolchain**: Rust 1.82.0 (`aarch64-linux-android`, `x86_64-linux-android`, `x86_64-pc-windows-msvc`)
- **SBOM & Audit Tools**: CycloneDX CLI 0.25.0, `cargo-audit`, `cargo-deny`, `cargo-cyclonedx`
