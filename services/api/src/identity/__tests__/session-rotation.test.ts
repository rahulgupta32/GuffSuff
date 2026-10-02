import { test } from "node:test";
import assert from "node:assert/strict";
import { Pool } from "pg";
import { SessionService } from "../session.service.js";

function fixture(overrides: Record<string, unknown> = {}) {
  const record = {
    token_id: "old-token",
    family_id: "family",
    user_id: "user",
    device_id: "device",
    session_id: "persisted-session",
    session_version: 2,
    is_compromised: false,
    is_revoked: false,
    is_rotated: false,
    session_revoked_at: null,
    device_revoked: false,
    expires_at: new Date(Date.now() + 60000),
    session_expires_at: new Date(Date.now() + 60000),
    ...overrides
  };
  const calls: string[] = [];
  const client = {
    query: async (sql: string) => {
      calls.push(sql);
      return { rows: sql.includes("SELECT rt.id") ? [record] : [] };
    },
    release: () => {}
  };
  return { calls, service: new SessionService({ connect: async () => client } as unknown as Pool) };
}

test("refresh tokens retain the persisted session and insert successor before foreign-key update", async () => {
  const { service, calls } = fixture();
  const result = await service.rotateRefreshToken("old-secret-token");
  assert.equal(result.sessionId, "persisted-session");
  const claims = service.verifyAccessToken(result.accessToken);
  assert.equal(claims.sessionId, result.sessionId);
  assert.equal(claims.sessionVersion, 2);
  assert.notEqual(result.refreshToken, "old-secret-token");
  assert.ok(
    calls.findIndex((s) => s.includes("INSERT INTO refresh_tokens")) <
      calls.findIndex((s) => s.includes("SET is_rotated"))
  );
});

for (const overrides of [
  { session_revoked_at: new Date() },
  { device_revoked: true },
  { session_expires_at: new Date(0) },
  { is_compromised: true }
]) {
  test(`refresh rejects revoked or expired state ${Object.keys(overrides)[0]}`, async () => {
    const { service, calls } = fixture(overrides);
    await assert.rejects(service.rotateRefreshToken("old-secret-token"), /invalid or revoked/);
    assert.ok(!calls.some((s) => s.includes("INSERT INTO refresh_tokens")));
    assert.equal(calls.at(-1), "ROLLBACK");
  });
}

test("reuse commits family and session revocation before rejecting the token", async () => {
  const { service, calls } = fixture({ is_rotated: true });
  await assert.rejects(service.rotateRefreshToken("old-secret-token"), /reuse detected/);
  assert.ok(calls.some((s) => s.includes("SET is_compromised = true")));
  assert.ok(calls.some((s) => s.includes("UPDATE sessions SET revoked_at")));
  assert.ok(calls.includes("COMMIT"));
  assert.ok(!calls.some((s) => s.includes("INSERT INTO refresh_tokens")));
});
