# Cryptographic Compatibility Spike Research Archive Manifest

> [!WARNING]
> **SECURITY WARNING**: THIS RESEARCH BRANCH AND ARCHIVE CONTAIN REJECTED CANDIDATE ARTIFACTS AND VULNERABLE DEPENDENCY LOCKFILES (`libcrux-secrets v0.0.5`, `libcrux-sha3 v0.0.8`). PROHIBITED FROM PRODUCTION USE.

---

## 1. Research Metadata & Target Identification

- **Research Branch**: `spike/crypto-provider-compatibility`
- **Final Commit SHA**: `63c3619831dbdbccc9f7a70f3f3aae577a34ac09`
- **Pull Request Reference**: `Pull Request #9` (Status: Closed without merge)
- **Evaluated Candidates**:
  - `OpenMLS v0.8.1` (Group Key Agreement — Production Baseline REJECTED per ADR-061)
  - `OpenMLS 0.9.0-rc.2` (Pre-Release Comparison — Research Only)
  - `libsignal v0.60.0` (Direct Messaging Historical Baseline — Not Recommended for Production)

---

## 2. Directory & Artifact Inventory

### Source Directories
- `spikes/crypto-eval/openmls/state-spike/`: Host 34-scenario lifecycle harness & cargo-deny setup.
- `spikes/crypto-eval/openmls/pre-release-comparison/`: `0.9.0-rc.2` pre-release comparison harness.
- `spikes/crypto-eval/openmls/android-neutral/`: Provider-neutral Android native boundary library (`guffsuff-android-neutral-boundary`).
- `spikes/crypto-eval/openmls/android-rejected-baseline/`: Rejected OpenMLS v0.8.1 Android research library (`openmls-android-rejected-baseline`).

### Results & Audit Log Directories
- `spikes/crypto-eval/results/openmls-vectors/`: Mapped vector test suite execution maps.
- `spikes/crypto-eval/results/openmls-security/`: `cargo-deny` license and advisory JSON summary outputs.
- `spikes/crypto-eval/openmls/state-spike/cargo_deny_advisories_full.log`: Full untruncated advisory log.

### Research Shared Library Checksums
- `aarch64-linux-android` Rejected OpenMLS `.so` SHA256: `56B4112296068059EE13E0CB6EF08FA0219259DA248F76FE8D67F6CFE153B3B8`
- `x86_64-linux-android` Rejected OpenMLS `.so` SHA256: `ADA74DF92B72DD7C46A8DD525D11587A71CFDC89A7278C77C261B0BEC34DE685`

---

## 3. Merging Prohibition & Branch Retention Policy

- **Why Not Merged to `main`**: Merging this branch would introduce vulnerable transitive lockfiles into the main repository, causing security scanner noise and accidental production import risks.
- **Retention Period**: `spike/crypto-provider-compatibility` remains isolated on GitHub as a temporary research reference branch until documentation and provider-neutral boundary PRs are merged.
- **Eventual Deletion**: The remote branch may be deleted once durable ADRs and research manifests are established in `main`.
- **Reproduction**: To reproduce host lifecycle and audit findings, check out `spike/crypto-provider-compatibility` in an isolated environment and run `cargo deny check advisories` and `cargo test`.
