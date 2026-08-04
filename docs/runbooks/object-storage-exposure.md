# Security Incident Runbook: Object Storage Public Exposure Response

> **Target Role**: `@devsecops-team`, `@security-lead`  
> **Trigger**: Alert indicating public read access enabled on S3 media bucket.

---

## Response Steps

1. **Enforce Block Public Access**: Apply S3 `BlockPublicAccess=true` bucket policy globally via AWS API / CLI.
2. **Revoke Presigned URLs**: Invalidate active KMS presigned URL signing keys.
3. **Confirm Ciphertext Safety**: Verify all uploaded media objects remain encrypted via client-side AES-256-GCM.
4. **Access Audit**: Audit S3 access logs for unauthorized GET requests during the exposure window.
