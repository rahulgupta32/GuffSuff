import assert from "node:assert";
import test from "node:test";
import { validateEnvironmentConfig } from "./index.js";

const VALID_PROD_ENV = {
  NODE_ENV: "production",
  PORT: "3000",
  DATABASE_URL: "postgresql://user:secret@db.guffsuff.internal:5432/guffsuff",
  REDIS_URL: "redis://redis.guffsuff.internal:6379",
  S3_ENDPOINT: "https://s3.guffsuff.internal",
  S3_BUCKET: "guffsuff-attachments",
  JWT_SECRET: "super-secure-production-jwt-secret-at-least-32-chars",
  CORS_ORIGIN: "https://admin.guffsuff.np",
  ALLOW_MOCK_CRYPTO: "false",
  ALLOW_DEV_OTP: "false",
  LOG_LEVEL: "info"
};

test("Validates correct production environment cleanly", () => {
  const config = validateEnvironmentConfig(VALID_PROD_ENV);
  assert.strictEqual(config.NODE_ENV, "production");
  assert.strictEqual(config.CORS_ORIGIN, "https://admin.guffsuff.np");
});

test("Fails closed on missing required secrets", () => {
  const invalidEnv = { ...VALID_PROD_ENV, JWT_SECRET: "short" };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /FAIL-CLOSED CONFIGURATION FAILURE.*JWT secret must be at least 32 characters/
  );
});

test("Fails closed on wildcard CORS in production", () => {
  const invalidEnv = { ...VALID_PROD_ENV, CORS_ORIGIN: "*" };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /Wildcard CORS origin is strictly forbidden/
  );
});

test("Fails closed on mock crypto enabled in production", () => {
  const invalidEnv = { ...VALID_PROD_ENV, ALLOW_MOCK_CRYPTO: "true" };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /Mock crypto mode is strictly forbidden/
  );
});

test("Fails closed on dev OTP mode enabled in production", () => {
  const invalidEnv = { ...VALID_PROD_ENV, ALLOW_DEV_OTP: "true" };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /Development OTP mode is strictly forbidden/
  );
});

test("Fails closed on debug log level in production", () => {
  const invalidEnv = { ...VALID_PROD_ENV, LOG_LEVEL: "debug" };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /Debug\/Trace logging is strictly forbidden/
  );
});

test("Fails closed on localhost database endpoint in production", () => {
  const invalidEnv = {
    ...VALID_PROD_ENV,
    DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/guffsuff"
  };
  assert.throws(
    () => validateEnvironmentConfig(invalidEnv),
    /Localhost database endpoint is forbidden/
  );
});
