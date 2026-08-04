# GuffSuff Third-Party Dependency Management Policy

> **Document Status**: Phase 2 Security Architecture Baseline

---

## 1. Dependency Admission Criteria

Before adding any third-party library to `package.json` or `pubspec.yaml`, developers MUST verify:

1. **Active Maintenance**: Repository updated within the last 6 months; active issue triage.
2. **Permissive License**: MIT, Apache-2.0, BSD-3-Clause, or MPL-2.0. (AGPL/GPL requires explicit legal review).
3. **Zero Known High CVEs**: Scanned clean via `npm audit` / `pub audit`.
4. **Minimal Transitive Dependencies**: Low total sub-dependency footprint.
5. **Zero Malicious Post-Install Scripts**: Package does not execute arbitrary native shell scripts upon installation.
