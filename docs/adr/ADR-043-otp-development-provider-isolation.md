# ADR-043: OTP Development-Provider Isolation

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Engineer, Release Manager

## Context
Accidentally bundling development OTP simulators in production builds risks exposing fake OTP channels and bypassing authentication safeguards.

## Decision
1. Isolate the development OTP simulator inside a separate package/module `@guffsuff/otp-simulator`.
2. Build entry points and bundler configurations strictly omit `@guffsuff/otp-simulator` from staging and production targets.
3. API startup routines perform explicit runtime checks that throw hard errors if simulator flags or modules are detected in production environments.
