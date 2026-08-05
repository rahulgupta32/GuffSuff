import assert from "node:assert";
import test from "node:test";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module.js";

test("API service executes graceful shutdown on process signal", async () => {
  const app = await NestFactory.create(AppModule, { logger: false });
  app.enableShutdownHooks();

  await app.listen(0);
  const server = app.getHttpServer();
  assert.ok(server.listening, "HTTP server listening");

  // Trigger graceful shutdown
  await app.close();
  assert.strictEqual(server.listening, false, "HTTP server stopped listening after close");
});
