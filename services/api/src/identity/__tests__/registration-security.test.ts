import { test } from "node:test";
import assert from "node:assert/strict";
import { Pool } from "pg";
import { AccountService } from "../account.service.js";
import { SessionService } from "../session.service.js";
import { PhoneNumberService } from "../phone-number.service.js";
import { OtpService } from "../otp.service.js";

const params = {
  challengeId: "018f3a2b-1234-7000-8000-000000000001",
  phoneNumber: "+9779841234567",
  displayName: "Test User",
  username: "test_user",
  installationId: "test-installation",
  deviceName: "Test Device",
  platform: "android" as const,
  appVersion: "0.1.0",
  osVersion: "15",
  termsAccepted: true,
  privacyAccepted: true
};

for (const scenario of ["different phone", "expired", "consumed", "unverified"]) {
  test(`registration rejects ${scenario} before writing account data`, async () => {
    const calls: string[] = [];
    const challenge = {
      phone_blind_index: new PhoneNumberService().generateBlindIndex(
        scenario === "different phone" ? "+9779851234567" : params.phoneNumber
      ),
      is_verified: scenario !== "unverified",
      expires_at: new Date(Date.now() + (scenario === "expired" ? -1000 : 60000)),
      consumed_at: scenario === "consumed" ? new Date() : null
    };
    let released = false;
    const client = {
      query: async (sql: string) => {
        calls.push(sql);
        return { rows: sql.includes("FROM otp_challenges") ? [challenge] : [] };
      },
      release: () => {
        released = true;
      }
    };
    const pool = { connect: async () => client } as unknown as Pool;
    const service = new AccountService(pool, {} as SessionService);
    await assert.rejects(service.registerAccount(params), /OTP challenge/);
    assert.ok(calls.includes("ROLLBACK"));
    assert.ok(!calls.some((sql) => sql.includes("INSERT INTO")));
    assert.ok(released);
  });
}

test("OTP verifier holds a transaction lock and persists failed attempts", async () => {
  const calls: string[] = [];
  let released = false;
  const challenge = {
    verifier_hash: "",
    attempts_count: 0,
    max_attempts: 3,
    expires_at: new Date(Date.now() + 60000),
    is_verified: false,
    consumed_at: null
  };
  const client = {
    query: async (sql: string, values?: unknown[]) => {
      calls.push(sql);
      if (sql.includes("UPDATE otp_challenges")) {
        assert.equal(values?.[1], false);
        challenge.attempts_count++;
      }
      return { rows: sql.includes("SELECT verifier_hash") ? [challenge] : [] };
    },
    release: () => {
      released = true;
    }
  };
  const service = new OtpService({ connect: async () => client } as unknown as Pool);
  challenge.verifier_hash = service.computeVerifierHash(params.challengeId, "654321");
  assert.equal(await service.verifyOtpChallenge(params.challengeId, "123456"), false);
  assert.equal(calls[0], "BEGIN");
  assert.ok(calls[1]?.includes("FOR UPDATE"));
  assert.equal(calls.at(-1), "COMMIT");
  assert.equal(challenge.attempts_count, 1);
  assert.ok(released);
  challenge.attempts_count = 3;
  await assert.rejects(service.verifyOtpChallenge(params.challengeId, "654321"), /exhausted/);
  assert.equal(calls.at(-1), "ROLLBACK");
});

test("production identity services reject development secret defaults", () => {
  const oldEnvironment = process.env.NODE_ENV;
  const names = [
    "OTP_VERIFIER_PEPPER_V1",
    "JWT_ACCESS_SECRET",
    "PHONE_HMAC_PEPPER",
    "PHONE_ENCRYPTION_SECRET"
  ];
  const previous = names.map((name) => process.env[name]);
  try {
    process.env.NODE_ENV = "production";
    names.forEach((name) => {
      delete process.env[name];
    });
    assert.throws(() => new PhoneNumberService(), /Required identity secret/);
    assert.throws(() => new OtpService({} as Pool), /Required identity secret/);
    assert.throws(() => new SessionService({} as Pool), /Required identity secret/);
  } finally {
    if (oldEnvironment === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = oldEnvironment;
    names.forEach((name, i) => {
      if (previous[i] === undefined) delete process.env[name];
      else process.env[name] = previous[i];
    });
  }
});
