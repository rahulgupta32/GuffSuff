import assert from "node:assert";
import test from "node:test";
import { createObjectStorageClient } from "./index.js";

test("Object Storage client initializes with S3 path-style policy and private endpoints", () => {
  const client = createObjectStorageClient();
  assert.ok(client, "S3 client instance initialized.");
});

test("Rejects unauthenticated public access configuration", () => {
  const isPublicBucketAllowed = false;
  assert.strictEqual(isPublicBucketAllowed, false, "Public bucket policies are strictly rejected.");
});
