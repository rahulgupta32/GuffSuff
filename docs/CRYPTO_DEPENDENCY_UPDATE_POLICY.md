# Cryptographic Dependency Update & Governance Policy

> **Document Status**: Strict Production Policy

---

## 1. Governance Rules for Cryptographic Dependencies

1. **Zero Unverified Upgrades**: No cryptographic dependency (including `libsignal` or `openmls`) may be upgraded in production without machine-verified SHA-256 checksums and tag commit SHAs.
2. **Version Reassessment Requirements**: Versions must be evaluated against public artifact availability, vulnerability history, breaking changes, and legal copyleft implications.
3. **`libsignal` Baseline Classification**: `v0.60.0` is designated as `Historical comparison baseline — not proposed for production integration`. Any future production upgrade requires custom reproducible build verification and legal approval.
4. **OpenMLS Baseline Classification**: `openmls-v0.8.1` is designated as the active evaluation candidate for RFC 9420 MLS group messaging.
