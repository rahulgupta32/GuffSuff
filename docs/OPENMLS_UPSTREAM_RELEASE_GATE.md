# OpenMLS Upstream Release Gate Specification

> **Document Status**: Official Release Gate Criteria for Future OpenMLS Upgrade Candidates

---

## 1. Release Acceptance Criteria (14-Point Checklist)

A future OpenMLS release candidate qualifies for formal evaluation and production consideration **ONLY** when all 14 criteria are completely satisfied:

1. **Official Stable Tag**: The candidate is an official stable release tag (e.g. `v0.9.0` or `v0.8.2`), not an unreleased `HEAD` commit or pre-release candidate.
2. **Peeled Commit Verification**: The tag resolves to an authentic, cryptographic commit SHA signed by official OpenMLS maintainers.
3. **Official Publication Source**: Packages are published to `crates.io` and verifiable via standard Cargo indexes.
4. **`libcrux-secrets` Remediation**: `Cargo.lock` resolves `libcrux-secrets >= 0.0.6` or completely removes the dependency.
5. **`libcrux-sha3` Remediation**: `Cargo.lock` resolves `libcrux-sha3 >= 0.0.10` or completely removes the dependency.
6. **Zero High/Critical RustSec Advisories**: `cargo audit` and `cargo deny check advisories` report zero critical or high vulnerabilities.
7. **`proc-macro-error2` Resolution**: The `proc-macro-error2` dependency path is removed, replaced with `manyhow`/`proc-macro2-diagnostics`, or formally documented and accepted as a host-only build-time risk.
8. **Workspace Test Execution**: `cargo test --workspace --locked` passes 100% of unit and integration tests.
9. **Vector Suite Execution**: Mapped test vector suites pass 100% of cases.
10. **Host Lifecycle Harness**: The 34-scenario host lifecycle harness (`state-spike`) passes 100% of scenarios.
11. **Storage Format Migration**: Schema and state persistence migration from the evaluated `0.8.1` format is fully documented and tested.
12. **Mobile Cross-Compilation**: Clean Android (`aarch64`, `x86_64`) and iOS (`aarch64`) cross-compilation builds execute without error.
13. **Artifact SBOM Validation**: Generated CycloneDX / SPDX SBOMs for built binary artifacts validate against schema requirements.
14. **External Security Review**: Formal security review accepts the updated cryptographic dependency tree.
