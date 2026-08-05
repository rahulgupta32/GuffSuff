# Cryptographic Integration Spike Proposal & Isolation Plan

> **Document Status**: Phase 6 Pre-Implementation Spike Proposal

---

## 1. Spike Boundaries & Safety Rules

1. **Isolation Boundary**: All spike code MUST reside in isolated test scripts or scratch packages (e.g. `spikes/crypto-eval/`).
2. **Zero Production Contamination**: Spike dependencies MUST NOT be imported or bundled into production package paths (`@guffsuff/api`, `@guffsuff/worker`, `@guffsuff/realtime`, `apps/mobile/lib`).
3. **Fictional Test Identities**: Only ephemeral synthetic keypairs and test vectors are permitted. Zero production user keys.
4. **Zero Custom Primitives**: Spikes use official library releases exclusively.

---

## 2. Target Candidate Spikes (Maximum 3 Proposals)

### Spike A: `libsignal-ffi` Build & Flutter FFI Feasibility
- **Goal**: Measure iOS/Android binary size impact and evaluate Dart FFI bindings for session serialization.
- **Deliverable**: Benchmark report on binary footprint and FFI memory overhead.

### Spike B: OpenMLS Group Key Agreement
- **Goal**: Evaluate TreeKEM epoch creation and message encryption/decryption latency across 5, 20, and 100 fictional device members.
- **Deliverable**: Performance profile of MLS epoch transitions.

### Spike C: `libsodium` Double Ratchet Prototype
- **Goal**: Validate Double Ratchet state serialization against published Signal test vectors.
- **Deliverable**: Test vector pass/fail report.
