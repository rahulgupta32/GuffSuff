# Contributing to GuffSuff

Thank you for your interest in contributing to GuffSuff! GuffSuff is a secure, privacy-focused, Nepal-first messaging platform.

## Branch Strategy

We follow a structured branch strategy:

- `main`: Protected, production-ready release branch. Force pushes and direct commits are strictly prohibited.
- `develop`: Integration branch for completed feature branches.
- `feature/<short-description>`: New application features.
- `fix/<short-description>`: Bug fixes.
- `security/<short-description>`: Security enhancements or vulnerability patches.
- `release/<version>`: Release candidate preparation.

## Commit Message Convention

All commits MUST follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` A new feature
- `fix:` A bug fix
- `security:` Security fix, crypto enhancement, or vulnerability patch
- `test:` Adding or updating tests
- `docs:` Documentation only changes
- `refactor:` Code refactoring without behavioral changes
- `build:` Build system or monorepo dependency changes
- `ci:` CI pipeline and workflow configuration updates
- `chore:` Maintenance tasks, repository housekeeping

Example:
```bash
git commit -m "feat(api): implement Nepal phone number E.164 normalization"
```

## Non-Negotiable Security Rules for Developers

1. **Zero Plaintext Server-Side**: Never log, trace, cache, store, or output plaintext message content or media files on backend services.
2. **No Invented Cryptography**: Crypto primitives must strictly go through `packages/crypto-adapter`.
3. **No Committed Secrets**: Pre-commit hooks (`gitleaks`) must pass prior to pushing.
4. **Devanagari Safety**: Ensure all mobile and web UI string processing supports proper Devanagari text shaping and UTF-8 / UTF-16 bounds.

## Pull Request Workflow

1. Create a topic branch from `develop`.
2. Ensure unit tests, integration tests, and static checks pass locally.
3. Submit a Pull Request targeting `develop` or `main`.
4. Ensure all GitHub Action CI checks pass (linting, tests, security scans).
5. Code review approval from `@rahulgupta32` is required for merge.
