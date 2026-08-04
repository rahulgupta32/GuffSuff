# Security Incident Runbook: Malicious Release Response

> **Target Role**: `@release-manager`, `@security-lead`  
> **Trigger**: Discovery of unauthorized, tampered, or malicious code compiled into published app release.

---

## Response Steps

1. **Unpublish Binary**: Immediately unpublish app release from Google Play Store and Apple App Store.
2. **Server API Gate**: Increment `minSupportedAppVersion` in API gateway to reject connections from compromised build numbers.
3. **Publish Safe Release**: Build and publish clean release signed with verified HSM credentials.
