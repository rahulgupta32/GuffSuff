# ADR-047: Device Identity and Revocation Model

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Mobile Lead, Backend Lead

## Context
Device management allows users to view and control logged-in client instances. Revoking a device must immediately terminate its access and refresh capabilities.

## Decision
1. Devices are registered with installation ID, display name, platform, app version, OS version. Invasive hardware/advertising identifiers (IMEI, MAC, IDFA) are strictly forbidden.
2. Device revocation marks `devices.is_revoked = true`, revokes linked refresh token families/sessions, and emits a realtime WebSocket notification.
3. Server-side session verification is authoritative; WebSocket notifications serve purely as client UI signals.
