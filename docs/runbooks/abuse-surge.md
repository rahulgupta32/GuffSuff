# Security Incident Runbook: Automated Abuse Surge Response

> **Target Role**: `@devsecops-team`, `@backend-lead`  
> **Trigger**: Sudden spike in automated bot registrations, OTP requests, or spam messages.

---

## Response Steps

1. **Enable Strict WAF Throttling**: Activate Cloudflare / WAF Bot Management challenge mode.
2. **Tighten Redis Rate Limits**: Reduce sliding window rate limits on OTP and registration endpoints.
3. **Enforce CAPTCHA**: Enable mandatory CAPTCHA challenges on `POST /api/v1/auth/otp/request`.
