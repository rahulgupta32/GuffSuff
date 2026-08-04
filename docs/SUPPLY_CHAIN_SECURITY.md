# GuffSuff Software Supply Chain Security Policy

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Citations**: NIST SP 800-218 (SSDF), SLSA (Supply-chain Levels for Software Artifacts) Framework

---

## 1. Approved Package Registries & Dependency Pinning

- **Approved Registries**: `npm` (Node.js/TypeScript packages), `pub.dev` (Flutter/Dart packages), `CocoaPods` (iOS native pods), `Maven Central / Google Maven` (Android Gradle plugins).
- **Lockfile Enforcement**: All package lockfiles (`package-lock.json`, `pubspec.lock`, `Podfile.lock`) MUST be committed to Git. CI builds MUST run `npm ci` / `flutter pub get --offline` to prevent unpinned lockfile drift (`SEC-DEPENDENCY-001`).
- **GitHub Actions Pinning**: GitHub Actions in `.github/workflows/` MUST be pinned to full 40-character commit SHAs (e.g. `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11`), prohibiting floating tags (`@v4`).

---

## 2. Container & Dependency Vulnerability Policies

- **Distroless Base Images**: Production Dockerfiles MUST use minimal Distroless or Alpine base images pinned to specific immutable digest hashes (`@sha256:...`).
- **Software Bill of Materials (SBOM)**: CI pipeline generates SPDX SBOM JSON for every production build.
- **Dependency Rejection Criteria**: Dependencies are rejected if they use unapproved licenses (AGPL/GPL without isolation, unknown), contain un-patched Critical/High CVEs > 7 days old, or execute unvetted post-install shell scripts (`scripts/postinstall`).
