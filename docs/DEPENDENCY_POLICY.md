# GuffSuff Dependency Management Policy

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Evaluation Criteria for New Dependencies

Before adding any third-party library or package to GuffSuff:

1. **Maintenance**: Must have active maintenance within the last 6 months.
2. **License**: Compatible open-source license (MIT, Apache 2.0, BSD-3-Clause, MPL-2.0).
3. **Security Audit**: Zero unpatched Critical or High CVEs in advisory databases.
4. **Minimal Footprint**: Avoid monolithic libraries for single helper functions.
5. **Pinning**: All dependencies must be pinned to exact versions or safe semver ranges.
