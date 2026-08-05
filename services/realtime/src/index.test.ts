import assert from "node:assert";
import test from "node:test";
import { RealtimeGateway } from "./realtime.gateway.js";

test("RealtimeGateway initializes cleanly", () => {
  const gateway = new RealtimeGateway();
  assert.ok(gateway, "RealtimeGateway initialized.");
});
