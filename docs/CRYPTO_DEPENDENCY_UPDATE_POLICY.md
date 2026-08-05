# Cryptographic Dependency & Security Patch Update Policy

> **Document Status**: Supply Chain & Vulnerability Management Standard

---

## 1. Monitoring & Patch Cadence

1. **Automated Vulnerability Scans**: Weekly `cargo audit` (Rust), `pnpm audit` (JS/TS), and `pub outdated` (Dart) runs.
2. **Patch SLA**: Security advisories with CVE rating `>= 7.0` (High/Critical) MUST be remediated within **7 business days**.
3. **Pinning Requirement**: All native cryptographic dependencies (`libsignal`, `openmls`, `libsodium`) MUST be pinned to exact commit SHAs or release tags. Wildcard or fuzzy version ranges (`^`, `~`) are strictly prohibited.

---

## 2. Emergency Update Protocol

In the event of a breaking vulnerability in an underlying cryptographic dependency, an emergency hotfix branch must be created, audited against existing state persistence formats, and validated with cross-platform test vectors before deployment.
