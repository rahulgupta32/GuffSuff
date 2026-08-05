# ADR-048: Privacy-Setting Defaults

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Product Lead, Security & Privacy Lead

## Context
Default privacy configurations dictate the initial exposure of user metadata. Privacy-by-default principles require strict initial settings.

## Decision
1. Phone Number Visibility: `Nobody`
2. Phone Discoverability: `Disabled`
3. Last Seen & Online Status: `Contacts Only`
4. Profile Photo: `Contacts Only` (Effective behavior in Phase 4 prior to contact features: `Nobody`).
5. Read Receipts: `Enabled` (User-configurable).
