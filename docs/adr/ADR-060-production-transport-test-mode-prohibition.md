# ADR-060: Production Transport-Test-Mode Prohibition

## Context
Phase 5 uses opaque development test payloads to demonstrate message transport before Phase 6 E2EE integration.

## Decision
1. Transport test mode MUST NOT be accessible in production binaries or staging environments.
2. Mobile clients enforce hard compile-time / runtime assertions (`bool.fromEnvironment('dart.vm.product')`) rejecting test payload creation in release mode.
3. API gateway rejects unencrypted development payloads in production mode.

## Consequences
- Eliminates risk of shipping unencrypted test transport modes to end users.
