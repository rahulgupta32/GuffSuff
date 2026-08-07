# ADR-065: Production Prohibition of Test Providers

- **Status**: Accepted
- **Date**: 2026-08-06

## Decision

Test providers marked with `isTestProvider: true` are hard-rejected in production builds via automated assertions (`assertProductionProviderSafety`). Release builds containing test providers will fail to initialize.
