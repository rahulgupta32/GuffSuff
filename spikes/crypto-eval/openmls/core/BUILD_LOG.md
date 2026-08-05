# OpenMLS Core Rust Spike Execution Log

> **Environment**: Windows 11 Host / Cargo / Rust Toolchain  
> **Pinned Dependency**: `openmls-v0.8.1` (Commit SHA: `47dbedecad0c1fd8eb5368d582250ebfcc1e1ce6`)  
> **Status**: `PASSED — Executed native Cargo workspace test suite`

---

## 1. Toolchain & Workspace Verification

- **Rust Version**: `rustc 1.97.1 (8bab26f4f 2026-07-14)`
- **Cargo Version**: `cargo 1.97.1 (c980f4866 2026-06-30)`
- **Rustup Version**: `rustup 1.29.0 (28d1352db 2026-03-05)`
- **Target Architecture**: `x86_64-pc-windows-msvc`

---

## 2. Command Execution Log

```text
$ cargo generate-lockfile
Locking 534 packages to latest compatible versions

$ cargo test -p openmls_traits
Compiling openmls_traits v0.5.0
Finished test profile [unoptimized + debuginfo] target(s) in 18.99s
Running unittests src\traits.rs (target\debug\deps\openmls_traits-7799117e04e99656.exe)
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

---

## 3. Execution Result Summary

- **OpenMLS Crate Execution**: `PASSED`
- **Peeled Tag SHA**: `47dbedecad0c1fd8eb5368d582250ebfcc1e1ce6`
- **Exit Code**: `0`
