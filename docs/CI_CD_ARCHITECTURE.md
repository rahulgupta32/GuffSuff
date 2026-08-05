# GuffSuff CI/CD Architecture & Security Policy

> **Document Status**: Phase 3 Development Platform Baseline

---

## CI/CD Workflow Pipeline Matrix

16 GitHub Actions workflows are configured under `.github/workflows/`:

1. `pr-validation.yml`: Pull request linting and typechecking.
2. `typescript.yml`: Workspace TypeScript compilation check.
3. `flutter.yml`: Flutter pub get, analyze, and widget tests.
4. `nextjs.yml`: Next.js 15 production bundle compilation.
5. `backend-unit.yml`: Service unit tests.
6. `integration.yml`: Docker Compose integration test suite.
7. `contracts.yml`: Zod schema contract compatibility validation.
8. `build.yml`: Monorepo build validation.
9. `secret-scan.yml`: Gitleaks commit history secret scanner.
10. `dependency-review.yml`: Automated PR dependency vulnerability check.
11. `sast.yml`: CodeQL static security analysis.
12. `container-scan.yml`: Trivy container vulnerability scanner.
13. `iac-scan.yml`: Checkov Dockerfile and Compose security scanner.
14. `sbom.yml`: Anchore SPDX SBOM generation.
15. `license-scan.yml`: License checker for unapproved open-source licenses.
16. `lockfile-validation.yml`: Enforces frozen pnpm lockfile integrity.
