# ADR-041: Phone-Number Parsing and Normalization

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Principal Security Architect, Lead Backend Engineer

## Context
Raw user input phone numbers vary in formatting (presentation spaces, dashes, Nepali numerals, local zero prefixes). Standardized E.164 normalization is required to prevent identity duplication and lookup failures while preserving privacy.

## Decision
1. Use `libphonenumber-js` for E.164 parsing. Default country code is Nepal (`+977`).
2. Convert Nepali numeral digits (`०-९`) to standard ASCII digits (`0-9`) at presentation boundary before parsing.
3. Phone numbers are stored encrypted (AES-256-GCM) with a keyed HMAC-SHA256 blind index (`phone_blind_index`). Plaintext E.164 is never stored in DB tables or logs.
