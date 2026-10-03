import { test } from "node:test";
import assert from "node:assert/strict";
import { ProductionOtpProvider } from "../otp.provider.js";

test("SMS adapter submits the documented API contract and never fabricates delivery or billing", async () => {
  const names = [
    "SMS_PROVIDER",
    "TWILIO_ACCOUNT_SID",
    "TWILIO_AUTH_TOKEN",
    "TWILIO_MESSAGING_SERVICE_SID"
  ];
  const previous = names.map((n) => process.env[n]);
  try {
    process.env.SMS_PROVIDER = "twilio";
    process.env.TWILIO_ACCOUNT_SID = `AC${"a".repeat(32)}`;
    process.env.TWILIO_AUTH_TOKEN = "test-token-not-real";
    process.env.TWILIO_MESSAGING_SERVICE_SID = `MG${"b".repeat(32)}`;
    let calls = 0;
    const request = (async (url: string | URL | Request, options?: RequestInit) => {
      calls++;
      assert.ok(String(url).startsWith("https://api.twilio.com/"));
      assert.equal(options?.redirect, "error");
      const body = new URLSearchParams(options?.body as string);
      assert.equal(body.get("To"), "+9779841234567");
      assert.ok(body.get("Body")?.includes("654321"));
      return new Response(JSON.stringify({ sid: `SM${"c".repeat(32)}`, status: "queued" }), {
        status: 201
      });
    }) as typeof fetch;
    const provider = new ProductionOtpProvider(request);
    const result = await provider.sendOtp("challenge", "blind-index", "654321", "+9779841234567");
    assert.equal(result.success, true);
    assert.equal(result.costAmount, null);
    await assert.rejects(provider.sendOtp("challenge", "blind-index", "654321"));
    assert.equal(calls, 1);
    const failed = new ProductionOtpProvider((async () => {
      throw new Error("secret-provider-error");
    }) as typeof fetch);
    const failure = await failed.sendOtp("challenge", "blind-index", "654321", "+9779841234567");
    assert.equal(failure.success, false);
    assert.ok(!JSON.stringify(failure).includes("secret-provider-error"));
    delete process.env.SMS_PROVIDER;
    await assert.rejects(provider.sendOtp("challenge", "blind-index", "654321", "+9779841234567"));
    assert.equal(calls, 1);
  } finally {
    names.forEach((n, i) => {
      if (previous[i] === undefined) delete process.env[n];
      else process.env[n] = previous[i];
    });
  }
});
