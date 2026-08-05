# Security Incident Runbook: SIM-Swap Account Takeover Response

> **Target Role**: `@trust-safety`, `@security-lead`  
> **Trigger**: User report of account lockout following SIM swap.

---

## Response Steps

1. **Lock Account**: Suspend account status to prevent unauthorized message sending.
2. **Verify Registration PIN**: Require user to supply 6-digit Registration Lock PIN (`AUTH-003`).
3. **Unlink Sessions**: Revoke active device sessions and public prekey bundles.
4. **Re-activate Session**: Issue fresh registration link after identity verification.
