# Security Incident Runbook: OTP Provider Compromise Response

> **Target Role**: `@devsecops-team`, `@backend-lead`  
> **Trigger**: Interruption or security breach alert from primary SMS OTP vendor.

---

## Response Steps

1. **Switch Gateway Provider**: Update API gateway environment variables to route OTP dispatches to secondary SMS vendor.
2. **Revoke API Tokens**: Deactivate compromised vendor API credentials.
3. **Audit SMS Delivery Logs**: Inspect SMS dispatch logs for unauthorized OTP numbers.
