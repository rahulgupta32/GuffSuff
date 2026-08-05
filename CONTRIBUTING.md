# Contributing to GuffSuff

> **Developer Guidelines & Security Commit Rules**

---

## Git Workflow & Branch Naming

All contributions must follow the branch naming conventions defined in `ADR-001`:

- `feature/<name>` — New capabilities or architectural components.
- `fix/<name>` — Bug fixes or stability patches.
- `security/<name>` — Security updates, threat models, or runbooks.
- `build/<name>` — Monorepo tooling, CI/CD, or infrastructure updates.
- `docs/<name>` — Documentation updates.

---

## Commit & PR Rules

1. **Commit Message Format**: Use Conventional Commits (`type(scope): subject`).
2. **Never Commit Secrets**: Ensure `gitleaks` passes before pushing commits.
3. **Commit Lockfiles**: All `pnpm-lock.yaml` changes must be committed.
4. **Pull Requests**: Submit PRs into `main`. Direct commits to `main` are blocked by branch protection rules.
