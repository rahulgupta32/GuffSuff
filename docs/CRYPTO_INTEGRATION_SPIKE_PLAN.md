# Cryptographic Integration Spike Proposal & Isolation Plan

> **Document Status**: Phase 6 Pre-Implementation Spike Authorization (Max 2 Spikes)

---

## 1. Authorized Spike Candidates

Only two initial compatibility spikes are authorized. No third custom-primitives or libsodium-based messaging spike is permitted.

### Candidate A: Official `libsignal` Compatibility Evaluation
- **Purpose**: Determine whether official supported artifacts can be integrated technically, assess Java/Swift mobile boundaries, assess Flutter platform-channel/FFI implications, evaluate official API surfaces, state persistence interfaces, test-vector availability, binary size, and licensing/maintenance blockers.
- **Rule**: This is NOT authorization to select `libsignal`. Do not copy internal Signal application code.

### Candidate B: OpenMLS Compatibility Evaluation
- **Purpose**: Evaluate RFC 9420 implementation compatibility, assess Rust-to-mobile bridge feasibility, credential-provider requirements, storage-provider interfaces, transaction/rollback requirements, group-state persistence, official test vectors, binary size, and security patch behavior.
- **Rule**: This is NOT authorization to use MLS for direct messaging or production groups.

---

## 2. Directory Structure & Automated Isolation

Spike workspace location: `spikes/crypto-eval/`
- `spikes/crypto-eval/libsignal/`
- `spikes/crypto-eval/openmls/`
- `spikes/crypto-eval/shared-results/`

### Production Workspace Isolation Invariants
1. Production package dependency graphs MUST NOT contain any spike package.
2. Mobile and backend production builds MUST NOT contain spike symbols.
3. Production lockfiles MUST NOT gain unused spike runtime dependencies.
4. Production build MUST fail if `CRYPTO_SPIKE_MODE` exists or if spike artifacts are selected via environment variables.
5. All spikes use synthetic fictional test identities ONLY.
