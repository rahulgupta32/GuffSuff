# Security Incident Runbook: Code-Signing Key Compromise

> **Target Role**: `@release-manager`, `@security-lead`  
> **Trigger**: Suspected or confirmed compromise of mobile APK/AAB or IPA signing keys.

---

## Response Steps

1. **Revoke Signing Certificates**: Revoke Apple Developer signing certificates and Android Play Console upload keys.
2. **Issue New Signing Keys**: Generate new hardware-backed signing keypair in HSM/Key Store.
3. **Deploy App Update**: Build and publish an emergency application update signed with the new release key.
4. **Force Upgrade**: Set `minSupportedAppVersion` in API gateway to force client app updates.
