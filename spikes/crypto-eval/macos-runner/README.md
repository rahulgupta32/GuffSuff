# macOS iOS Native Execution Package for Cryptographic Spikes

> **MARKING**: `ISOLATED SPIKE RUNNER`  
> **STATUS**: `BLOCKED — macOS runner required`

---

## 1. Overview & Requirements

This execution package is designed for execution on an isolated macOS runner equipped with Xcode 15+ and CocoaPods. It provides automated build and test scripts for compiling `libsignal` and `OpenMLS` for iOS (`arm64` device and `x86_64` simulator).

---

## 2. Included Execution Scripts

- `run-libsignal-ios.sh`: Resolves Swift dependencies and builds `libsignal` iOS native spike.
- `run-openmls-ios.sh`: Cross-compiles `openmls` for `aarch64-apple-ios` and iOS simulator targets.
- `run-flutter-ios.sh`: Builds isolated Flutter iOS application.
- `collect-results.sh`: Gathers test exit codes, binary sizes, and updates `results.json`.
