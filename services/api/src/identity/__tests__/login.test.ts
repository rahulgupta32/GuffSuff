import { test } from "node:test";
import assert from "node:assert/strict";
import { Pool, PoolClient } from "pg";
import * as argon2 from "argon2";
import { LoginService } from "../login.service.js";
import { SessionService } from "../session.service.js";
import { PhoneNumberService } from "../phone-number.service.js";

const input = {
  challengeId: "018f3a2b-1234-7000-8000-000000000001",
  phoneNumber: "+9779841234567",
  installationId: "install",
  deviceName: "Test",
  platform: "android" as const,
  appVersion: "0.1.0",
  osVersion: "15"
};
function fixture(
  options: {
    challenge?: Record<string, unknown>;
    user?: boolean;
    state?: string;
    revoked?: boolean;
    pinHash?: string;
    failures?: number;
    sessionError?: boolean;
  } = {}
) {
  const calls: string[] = [];
  let sessionCount = 0;
  const client = {
    query: async (sql: string) => {
      calls.push(sql);
      if (sql.includes("FROM otp_challenges"))
        return {
          rows: [
            {
              is_verified: true,
              consumed_at: null,
              expires_at: new Date(Date.now() + 60000),
              phone_blind_index: new PhoneNumberService().generateBlindIndex(input.phoneNumber),
              ...options.challenge
            }
          ]
        };
      if (sql.includes("FROM users u"))
        return {
          rows:
            options.user === false ? [] : [{ id: "user", account_state: options.state ?? "active" }]
        };
      if (sql.includes("SELECT pin_argon2_hash"))
        return { rows: options.pinHash ? [{ pin_argon2_hash: options.pinHash }] : [] };
      if (sql.includes("COUNT(*)")) return { rows: [{ failures: options.failures ?? 0 }] };
      if (sql.includes("SELECT id, is_revoked"))
        return { rows: [{ id: "device", is_revoked: options.revoked ?? false }] };
      return { rows: [] };
    },
    release: () => {}
  };
  const sessions = {
    createSession: async (_user: string, _device: string, tx: PoolClient) => {
      assert.equal(tx, client);
      sessionCount++;
      if (options.sessionError) throw new Error("session failure");
      return {
        accessToken: "access",
        refreshToken: "refresh",
        sessionId: "session",
        familyId: "family",
        expiresInSeconds: 900
      };
    }
  } as unknown as SessionService;
  return {
    calls,
    count: () => sessionCount,
    service: new LoginService({ connect: async () => client } as unknown as Pool, sessions)
  };
}
for (const challenge of [
  { is_verified: false },
  { consumed_at: new Date() },
  { expires_at: new Date(0) },
  { phone_blind_index: "wrong-phone" }
]) {
  test(`login rejects challenge ${Object.keys(challenge)[0]} before session creation`, async () => {
    const f = fixture({ challenge });
    await assert.rejects(f.service.login(input));
    assert.equal(f.count(), 0);
    assert.equal(f.calls.at(-1), "ROLLBACK");
  });
}
test("new phone requires registration without consuming verification", async () => {
  const f = fixture({ user: false });
  assert.deepEqual(await f.service.login(input), { registrationRequired: true });
  assert.equal(f.count(), 0);
  assert.ok(!f.calls.some((s) => s.includes("SET consumed_at")));
});
test("existing account login consumes challenge and shares session transaction", async () => {
  const f = fixture();
  const result = await f.service.login(input);
  assert.equal(result.registrationRequired, false);
  assert.equal(f.count(), 1);
  assert.ok(f.calls.some((s) => s.includes("SET consumed_at")));
  assert.equal(f.calls.at(-1), "COMMIT");
});
for (const options of [{ state: "suspended" }, { revoked: true }, { sessionError: true }]) {
  test(`login fails closed for ${Object.keys(options)[0]}`, async () => {
    const f = fixture(options);
    await assert.rejects(f.service.login(input));
    assert.equal(f.calls.at(-1), "ROLLBACK");
  });
}
test("PIN lock cannot be bypassed; wrong attempts commit and lockout stops new verification", async () => {
  const pinHash = await argon2.hash("654321:default_guffsuff_pin_pepper_v1_32chars!!");
  const missing = fixture({ pinHash });
  await assert.rejects(missing.service.login(input));
  assert.equal(missing.count(), 0);
  const wrong = fixture({ pinHash });
  await assert.rejects(wrong.service.login({ ...input, registrationLockPin: "123456" }));
  assert.ok(wrong.calls.some((s) => s.includes("INSERT INTO registration_lock_attempts")));
  assert.equal(wrong.calls.at(-1), "COMMIT");
  assert.equal(wrong.count(), 0);
  const locked = fixture({ pinHash, failures: 5 });
  await assert.rejects(locked.service.login({ ...input, registrationLockPin: "654321" }));
  assert.equal(locked.count(), 0);
  const correct = fixture({ pinHash });
  const result = await correct.service.login({ ...input, registrationLockPin: "654321" });
  assert.equal(result.registrationRequired, false);
});
