# GuffSuff Build Reproducibility Policy

> **Document Status**: Phase 3 Development Platform Baseline

---

## Reproducible Build Guarantee

1. **Frozen Dependencies**: All builds enforce `pnpm install --frozen-lockfile`.
2. **Pinned Runtimes**: Node.js `24.15.0`, TypeScript `5.7.3`, pnpm `11.20.0`, Docker base images `node:24.15.0-alpine3.21`.
3. **Deterministic Output**: Build tasks managed via Turborepo (`turbo.json`).
