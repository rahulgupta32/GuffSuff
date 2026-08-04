# Security Incident Runbook: Compromised User Device Key Response

> **Target Role**: `@mobile-team`, `@security-lead`  
> **Trigger**: Report of lost device, stolen phone, or extracted identity key.

---

## Response Steps

1. **Invoke Device Revocation API**: Invoke `POST /api/v1/devices/:id/revoke` to mark device status `REVOKED`.
2. **Purge Prekeys**: Server immediately deletes all public prekeys associated with the compromised device.
3. **Session Invalidation**: Invalidate active JWT refresh token in Redis and drop active WebSocket connection.
4. **Notify User**: Send SMS alert to verified phone number notifying of device unlinking.
