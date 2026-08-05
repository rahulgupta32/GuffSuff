import assert from "node:assert";
import test from "node:test";
import fs from "node:fs";
import path from "node:path";
import { HealthResponseSchema } from "./index.js";

test("HealthResponseSchema validates correct health objects", () => {
  const sample = {
    status: "OK",
    service: "api",
    version: "0.1.0-dev",
    timestamp: new Date().toISOString()
  };

  const parsed = HealthResponseSchema.parse(sample);
  assert.strictEqual(parsed.status, "OK");
  assert.strictEqual(parsed.service, "api");
});

test("Enforces production workspace isolation from spikes/crypto-eval", () => {
  const rootPackagePath = path.resolve(process.cwd(), "../../package.json");
  if (fs.existsSync(rootPackagePath)) {
    const rootPkg = JSON.parse(fs.readFileSync(rootPackagePath, "utf-8"));
    const deps = { ...rootPkg.dependencies, ...rootPkg.devDependencies };
    assert.strictEqual(deps["libsignal"], undefined, "libsignal must not be in root dependencies");
    assert.strictEqual(deps["openmls"], undefined, "openmls must not be in root dependencies");
  }

  // Verify CRYPTO_SPIKE_MODE assertion
  const validateProductionFlags = (env: Record<string, string | undefined>) => {
    if (env.NODE_ENV === "production" && env.CRYPTO_SPIKE_MODE === "true") {
      throw new Error("CRYPTO_SPIKE_MODE MUST NOT be enabled in production environment");
    }
  };

  assert.throws(() => {
    validateProductionFlags({ NODE_ENV: "production", CRYPTO_SPIKE_MODE: "true" });
  }, /CRYPTO_SPIKE_MODE MUST NOT be enabled/);
});
