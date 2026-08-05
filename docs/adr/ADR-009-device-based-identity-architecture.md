# ADR-009: Device-Based Identity & Multi-Device Key Architecture

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

Users may register multiple physical mobile devices over time or switch devices upon phone upgrade. To support E2EE securely without sharing private keys across devices, identity must be rooted at the device level.

---

## Decision

User identity is bound to a **User Account** which owns one or more registered **Devices**.

### Key Principles

1. Each physical device generates its own unique Ed25519 / Curve25519 Identity Key Pair upon registration.
2. The server treats each device as an independent E2EE messaging endpoint.
3. Message fan-out: Sender client encrypts separate envelope payloads for every active device registered under the recipient's user account (and for the sender's other registered devices for self-sync).
4. Device Revocation: Unlinking a device revokes its session and prekey bundles immediately on the server.

---

## Security Consequences

- Private keys never leave the device hardware enclave.
- Device revocation prevents compromised old devices from decrypting newly sent messages.
