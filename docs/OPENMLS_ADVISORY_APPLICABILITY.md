# OpenMLS Advisory Reachability & Applicability Matrix

> **Document Status**: Official Advisory Applicability Assessment (Phase 6 Cryptographic Compatibility Spike)

---

## 1. Summary of Evaluated RustSec Advisories

| Advisory ID | CVSS / Severity | Crate | Current Version | Fixed Version | Role | Host Build | Android ARM64 | Android x86_64 | iOS ARM64 | Production Reachability |
|-------------|-----------------|-------|-----------------|---------------|------|------------|---------------|----------------|-----------|-------------------------|
| **RUSTSEC-2026-0212** | High | `libcrux-secrets` | `0.0.5` | `>=0.0.6` | Runtime | Present | **APPLICABLE** | Present | **APPLICABLE** | **Vulnerable API reachable on ARM64** |
| **RUSTSEC-2026-0207** | Medium | `libcrux-sha3` | `0.0.8` | `>=0.0.10` | Runtime | **APPLICABLE** | **APPLICABLE** | **APPLICABLE** | **APPLICABLE** | **Incremental squeeze API reachable** |
| **RUSTSEC-2026-0208** | Medium | `libcrux-sha3` | `0.0.8` | `>=0.0.10` | Runtime | **APPLICABLE** | Present | **APPLICABLE** | Present | **AVX2 SHAKE-256 routine reachable on x86_64** |
| **RUSTSEC-2026-0173** | Informational | `proc-macro-error2` | `2.0.1` | None | Build (proc-macro) | **APPLICABLE** | Stripped | Stripped | Stripped | Host build macro only |
| **RUSTSEC-2021-0139** | Informational | `ansi_term` | `0.12.1` | None | Test-only | **APPLICABLE** | Stripped | Stripped | Stripped | Test harness runner only |

---

## 2. Detailed Advisory Records (16-Field System)

### Record 1: RUSTSEC-2026-0212 (`libcrux-secrets`)
1. **Advisory ID**: `RUSTSEC-2026-0212`
2. **CVSS / Severity**: High
3. **Crate and Version**: `libcrux-secrets v0.0.5`
4. **Fixed Version**: `>=0.0.6`
5. **Exact Dependency Path**: `libcrux-secrets 0.0.5 -> libcrux-traits 0.0.6 -> libcrux-sha3 0.0.8 -> hpke-rs 0.6.1 -> openmls_rust_crypto 0.5.1 -> openmls 0.8.1`
6. **Feature Path**: `openmls/openmls_rust_crypto` -> `hpke-rs/default` -> `libcrux-sha3` -> `libcrux-traits` -> `libcrux-secrets`
7. **Host Build Applicability**: Present in build graph (x86_64 host).
8. **Android ARM64 Applicability**: **HIGHLY APPLICABLE**. Compiled into `.so` shared library on ARM64 Android devices.
9. **Android x86_64 Applicability**: Present in `.so` shared library on x86_64 Android emulators.
10. **iOS ARM64 Applicability**: **HIGHLY APPLICABLE**. Compiled into iOS mobile static/shared library.
11. **Classification**: Runtime Cryptographic Code.
12. **Vulnerable API**: Constant-time swap and select on ARM64 (`libcrux_secrets::select_u8` inline assembly `cmp` selector instruction).
13. **Reached by OpenMLS / HPKE**: **YES**. Reached by HPKE-RS / libcrux scalar and secret key selection routines during MLS ciphersuite operations.
14. **Supporting Evidence**: Source inspection of `libcrux-secrets v0.0.5` confirms `cmp` instruction operating on 32-bit registers containing unmasked high 24 bits. Upstream PR #1461 fixed this by switching to `tst`.
15. **Residual Uncertainty**: Register state produced by LLVM compiler optimization determines whether high bits are non-zero at execution time.
16. **Required Remediation**: Require `libcrux-secrets >= 0.0.6` or upgrade OpenMLS crypto backend baseline.

---

### Record 2: RUSTSEC-2026-0207 (`libcrux-sha3`)
1. **Advisory ID**: `RUSTSEC-2026-0207`
2. **CVSS / Severity**: Medium
3. **Crate and Version**: `libcrux-sha3 v0.0.8`
4. **Fixed Version**: `>=0.0.10`
5. **Exact Dependency Path**: `libcrux-sha3 0.0.8 -> hpke-rs 0.6.1 -> openmls_rust_crypto 0.5.1 -> openmls 0.8.1`
6. **Feature Path**: `openmls/openmls_rust_crypto` -> `hpke-rs` -> `libcrux-sha3`
7. **Host Build Applicability**: **APPLICABLE**.
8. **Android ARM64 Applicability**: **APPLICABLE**.
9. **Android x86_64 Applicability**: **APPLICABLE**.
10. **iOS ARM64 Applicability**: **APPLICABLE**.
11. **Classification**: Runtime Cryptographic Hashing Code.
12. **Vulnerable API**: Incremental portable SHAKE XOF `squeeze` function when called multiple times with output lengths not cleanly divisible by `RATE` (168 for SHAKE128, 136 for SHAKE256).
13. **Reached by OpenMLS / HPKE**: **YES**. Linked into HPKE-RS cryptographic operations.
14. **Supporting Evidence**: Source inspection of `libcrux-sha3 v0.0.8` portable squeeze buffer handling. Upstream PR #1389 fixed incomplete block buffering.
15. **Residual Uncertainty**: Standard MLS Ciphersuite 1 uses HKDF-SHA256; however, SHAKE XOF routines are compiled into the binary unconditionally via `libcrux-sha3`.
16. **Required Remediation**: Require `libcrux-sha3 >= 0.0.10`.

---

### Record 3: RUSTSEC-2026-0208 (`libcrux-sha3`)
1. **Advisory ID**: `RUSTSEC-2026-0208`
2. **CVSS / Severity**: Medium
3. **Crate and Version**: `libcrux-sha3 v0.0.8`
4. **Fixed Version**: `>=0.0.10`
5. **Exact Dependency Path**: `libcrux-sha3 0.0.8 -> hpke-rs 0.6.1 -> openmls_rust_crypto 0.5.1 -> openmls 0.8.1`
6. **Feature Path**: `openmls/openmls_rust_crypto` -> `hpke-rs` -> `libcrux-sha3`
7. **Host Build Applicability**: **APPLICABLE** on x86_64 hosts supporting AVX2.
8. **Android ARM64 Applicability**: Present in build tree (AVX2 path unexecuted at runtime on ARM64 hardware).
9. **Android x86_64 Applicability**: **APPLICABLE** on x86_64 Android emulators with AVX2 support.
10. **iOS ARM64 Applicability**: Present in build tree (AVX2 path unexecuted at runtime on ARM64 hardware).
11. **Classification**: Runtime Cryptographic Hashing Code.
12. **Vulnerable API**: `libcrux_sha3::avx2::x4::shake256` (out-of-bounds indexing panic for output buffers > 32 bytes and not divisible by 8).
13. **Reached by OpenMLS / HPKE**: **YES**. Compiled into x86_64 AVX2 targets.
14. **Supporting Evidence**: Source inspection of `libcrux-sha3 v0.0.8` AVX2 module. Upstream PR #1456 fixed indexing logic.
15. **Residual Uncertainty**: Panic occurs when non-standard output buffer lengths are passed.
16. **Required Remediation**: Require `libcrux-sha3 >= 0.0.10`.

---

### Record 4: RUSTSEC-2026-0173 (`proc-macro-error2`)
1. **Advisory ID**: `RUSTSEC-2026-0173`
2. **CVSS / Severity**: Informational / Unmaintained Crate
3. **Crate and Version**: `proc-macro-error2 v2.0.1`
4. **Fixed Version**: None (`No safe upgrade is available!`)
5. **Exact Dependency Path**: `proc-macro-error2 2.0.1 -> hax-lib-macros 0.3.6 -> hax-lib 0.3.6 -> core-models 0.0.5 -> libcrux-intrinsics 0.0.6 -> libcrux-sha3 0.0.8 -> hpke-rs 0.6.1 -> openmls_rust_crypto 0.5.1 -> openmls 0.8.1`
6. **Feature Path**: `openmls/openmls_rust_crypto` -> `hpke-rs` -> `libcrux-sha3` -> `hax-lib` -> `hax-lib-macros`
7. **Host Build Applicability**: **APPLICABLE** during host compilation (executed by `rustc` host compiler).
8. **Android ARM64 Applicability**: **NON-APPLICABLE** (stripped host procedural macro).
9. **Android x86_64 Applicability**: **NON-APPLICABLE** (stripped host procedural macro).
10. **iOS ARM64 Applicability**: **NON-APPLICABLE** (stripped host procedural macro).
11. **Classification**: Build-time Procedural Macro.
12. **Vulnerable API**: N/A (unmaintained crate advisory).
13. **Reached by OpenMLS / HPKE**: Executed during macro expansion when compiling `hax-lib-macros`.
14. **Supporting Evidence**: Author announcement in `proc-macro-error-2` issue #17 confirming end of maintenance.
15. **Residual Uncertainty**: Crate contains no known remote execution CVE, but poses build-toolchain maintenance risk.
16. **Required Remediation**: Replace `proc-macro-error2` with `manyhow` in upstream `hax-lib-macros`.

---

### Record 5: RUSTSEC-2021-0139 (`ansi_term`)
1. **Advisory ID**: `RUSTSEC-2021-0139`
2. **CVSS / Severity**: Informational / Deprecated Crate
3. **Crate and Version**: `ansi_term v0.12.1`
4. **Fixed Version**: None
5. **Exact Dependency Path**: `ansi_term 0.12.1 -> openmls_test 0.2.1 -> openmls 0.8.1`
6. **Feature Path**: `openmls/test-utils` -> `openmls_test` -> `ansi_term`
7. **Host Build Applicability**: **APPLICABLE** when running host test runners.
8. **Android ARM64 Applicability**: **NON-APPLICABLE** (test-only dependency).
9. **Android x86_64 Applicability**: **NON-APPLICABLE** (test-only dependency).
10. **iOS ARM64 Applicability**: **NON-APPLICABLE** (test-only dependency).
11. **Classification**: Test-only Dependency.
12. **Vulnerable API**: N/A.
13. **Reached by OpenMLS / HPKE**: Formats terminal output in test execution.
14. **Supporting Evidence**: Upstream deprecation notice.
15. **Residual Uncertainty**: None.
16. **Required Remediation**: Exclude `test-utils` feature from production release builds.
