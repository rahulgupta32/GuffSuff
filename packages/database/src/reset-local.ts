import { createDatabasePool } from "./index.js";

async function resetLocalDatabase() {
  if (process.env.NODE_ENV === "production" || process.env.APP_ENV === "production") {
    console.error("[RESET-BLOCKED] Cannot reset database in production environment!");
    process.exit(1);
  }
  console.log("[RESET-LOCAL] Resetting local development database tables...");
  const pool = createDatabasePool();
  try {
    await pool.query("DROP SCHEMA public CASCADE; CREATE SCHEMA public;");
    console.log("[RESET-LOCAL] Database reset complete.");
  } finally {
    await pool.end();
  }
}

resetLocalDatabase().catch((err) => {
  console.error("[RESET-ERROR]", err);
  process.exit(1);
});
