# ADR-064: Compile-Time Provider Registration Policy

- **Status**: Accepted
- **Date**: 2026-08-06

## Decision

All native cryptographic providers must be statically registered at compile time. Dynamic loading of unverified shared libraries from writable application paths is strictly prohibited to prevent arbitrary code execution vulnerabilities.
