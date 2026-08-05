# ADR-017: Mobile Hardware-Backed Key Storage

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Mobile Architect, Security Lead
- **Decision Status**: Proposed

## Context
Private identity keys stored in standard mobile flash storage or shared preferences can be extracted by malware or physical device dumps.

## Decision
Mobile application private keys MUST be stored strictly in platform hardware enclaves via `flutter_secure_storage` (iOS Keychain / Android Keystore).
