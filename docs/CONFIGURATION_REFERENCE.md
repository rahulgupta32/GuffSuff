# GuffSuff Environment Configuration Reference

> **Document Status**: Phase 3 Development Platform Baseline  
> **Rule**: Insecure defaults in production environments MUST fail startup immediately (`ADR-034`).

---

## Configuration Variable Reference Matrix

| Variable Name          | Environment    | Classification | Default Value                                                                | Production Requirement                 | Failure Behavior                |
| :--------------------- | :------------- | :------------- | :--------------------------------------------------------------------------- | :------------------------------------- | :------------------------------ |
| `NODE_ENV`             | All            | Non-secret     | `development`                                                                | MUST be `production`                   | Fails closed on startup         |
| `APP_ENV`              | All            | Non-secret     | `local`                                                                      | `local` / `staging` / `production`     | Fails closed on startup         |
| `PORT`                 | API / Realtime | Non-secret     | `3000` / `3001`                                                              | Express / Socket port                  | Fallback to default             |
| `DATABASE_URL`         | Services       | **Secret**     | `postgresql://guffsuff_user:guffsuff_local_pass@localhost:5432/guffsuff_dev` | MUST be explicit TLS connection string | Fails closed on startup         |
| `REDIS_URL`            | Services       | **Secret**     | `redis://localhost:6379`                                                     | MUST be explicit TLS connection string | Fails closed on startup         |
| `S3_ENDPOINT`          | Services       | Non-secret     | `http://localhost:9000`                                                      | S3 endpoint URL                        | Fallback to default S3 endpoint |
| `S3_BUCKET_NAME`       | Services       | Non-secret     | `guffsuff-media-local`                                                       | Private production bucket name         | Fails closed on startup         |
| `S3_ACCESS_KEY`        | Services       | **Secret**     | `guffsuff_minio_local_key`                                                   | IAM Workload identity key              | Fails closed on startup         |
| `S3_SECRET_KEY`        | Services       | **Secret**     | `guffsuff_minio_local_secret`                                                | IAM Workload secret key                | Fails closed on startup         |
| `JWT_ACCESS_SECRET`    | Services       | **Secret**     | `dev_only_jwt_access_secret_do_not_use_in_prod`                              | Hardware-backed secret (min 64 chars)  | Fails closed on startup         |
| `JWT_REFRESH_SECRET`   | Services       | **Secret**     | `dev_only_jwt_refresh_secret_do_not_use_in_prod`                             | Hardware-backed secret (min 64 chars)  | Fails closed on startup         |
| `CORS_ALLOWED_ORIGINS` | API / Admin    | Non-secret     | `http://localhost:3000,http://localhost:3002`                                | Explicit allowlist (No wildcards)      | Fails closed on startup         |
| `MOCK_CRYPTO_ENABLED`  | Mobile / API   | Non-secret     | `true` (Local only)                                                          | MUST be `false` or absent              | Build / Startup fails           |
