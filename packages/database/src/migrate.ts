import { createDatabasePool } from "./index.js";

async function runMigrations() {
  console.log("[MIGRATIONS] Checking schema_migrations table...");
  const pool = createDatabasePool();
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("[MIGRATIONS] schema_migrations ready.");
  } finally {
    await pool.end();
  }
}

runMigrations().catch((err) => {
  console.error("[MIGRATIONS-ERROR]", err);
  process.exit(1);
});
