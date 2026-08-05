# GuffSuff Developer Security Checklist

> **Document Status**: Phase 3 Development Platform Baseline

---

## Developer Security Checklist

- [ ] `gitleaks` pre-commit scan executed and clean.
- [ ] No hardcoded secrets, private keys, or credentials in source code.
- [ ] `pnpm-lock.yaml` updated and committed.
- [ ] All new environment variables added to `.env.example` and `docs/CONFIGURATION_REFERENCE.md`.
- [ ] No mock crypto symbols introduced in production packages.
- [ ] All APIs validate inputs using `@guffsuff/contracts` Zod schemas.
- [ ] Mobile build displays development banner when running `development` flavor.
