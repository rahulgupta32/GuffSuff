# GuffSuff Security Policy

## Pre-Production / Draft Warning

> **WARNING**: GuffSuff is currently under active architecture and security development. Features in early development phases may use non-production mock crypto adapters until explicit approval of the production cryptographic implementation. **DO NOT deploy or use GuffSuff in production environments without official release sign-off.**

## Reporting a Vulnerability

We take the security and privacy of GuffSuff extremely seriously. If you believe you have found a security vulnerability in GuffSuff, please report it to us immediately.

### How to Report

**DO NOT submit public GitHub issues for security vulnerabilities.**

Instead, please send an encrypted email or report directly to:
- **Repository Owner**: Rahul Gupta (`@rahulgupta32`)
- **Email**: `security@guffsuff.com` (or direct security contact channel)

Please include:
1. Type of vulnerability (e.g., OTP bypass, cryptographic flaw, IDOR, sensitive logging leakage)
2. Detailed steps to reproduce the issue
3. Affected component (e.g., `services/api`, `packages/crypto-adapter`, `apps/mobile`)
4. Impact assessment and potential mitigation

### Response SLA

- **Acknowledgment**: Within 24 hours
- **Initial Triage & Assessment**: Within 72 hours
- **Patch & Disclosure Plan**: Depending on severity (Critical: < 7 days, High: < 14 days)

## Security Architecture & Baseline

GuffSuff adheres to:
- **OWASP MASVS** (Mobile Application Security Verification Standard)
- **OWASP ASVS** (Application Security Verification Standard v4.0)
- **STRIDE-based Threat Modeling** (see [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md))
- **Data Minimization & Zero-Trust Metadata Principles** (see [`docs/PRIVACY_MODEL.md`](docs/PRIVACY_MODEL.md))

## Secret & Data Safeguards

- Never commit secrets, private keys, API credentials, OTP tokens, or environment files.
- Pre-commit scanning (`gitleaks`) and GitHub Secret Scanning are strictly enforced across all branches.
- Production logs, traces, and metrics MUST NEVER contain plaintext message content, encryption keys, or raw phone numbers.
