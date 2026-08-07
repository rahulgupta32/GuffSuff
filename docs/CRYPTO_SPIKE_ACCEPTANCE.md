# Cryptographic Compatibility Spike Acceptance Criteria & Status

> **Document Status**: Active Spike Verification Criteria

---

## 1. Executive Summary & Status Matrix

- **OpenMLS Host Protocol Compatibility**: `PARTIAL PASS — 34-point group lifecycle and state persistence harness executed with zero failures; 23/25 vector suites passed.`
- **OpenMLS Dependency Advisory Gate**: `FAILED — Audit flagged RUSTSEC-2026-0173 (proc-macro-error2), RUSTSEC-2026-0212 (libcrux-secrets), RUSTSEC-2026-0207, and RUSTSEC-2026-0208 (libcrux-sha3).`
- **OpenMLS License-Policy Gate**: `PASSED — Explicit allowlist in deny.toml satisfies licensing requirements for all 188 transitive dependencies.`
- **OpenMLS Production Baseline**: `REJECTED (ADR-061)`
- **Built-Artifact SBOM Status**: `PARTIAL — source dependency SBOM and native artifact inspection completed; complete built-artifact SBOM not yet generated.`
- **Provider-Neutral Android Cross-Compilation**: `PASSED`
- **Provider-Neutral Android Runtime**: `NOT EXECUTED — Android runtime instrumentation evidence not provided`
- **Rejected OpenMLS v0.8.1 Android Cross-Compilation**: `PASSED — research baseline only`
- **Rejected OpenMLS v0.8.1 Android Runtime**: `NOT EXECUTED — Android runtime instrumentation evidence not provided`
- **OpenMLS 0.9.0-rc.2 Evaluation**: `PRE-RELEASE RESEARCH ONLY — NOT A PRODUCTION CANDIDATE`
- **Production Cryptographic Integration**: `NOT AUTHORIZED`
