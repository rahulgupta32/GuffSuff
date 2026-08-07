import { createDatabasePool } from "./index.js";
import * as fs from "fs";
import * as path from "path";

export async function runMigrations() {
  console.log("[MIGRATIONS] Checking schema_migrations table...");
  const pool = createDatabasePool();
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    const migrationsDir =
      typeof __dirname !== "undefined"
        ? path.resolve(__dirname, "../migrations")
        : path.resolve(process.cwd(), "packages/database/migrations");

    if (fs.existsSync(migrationsDir)) {
      const files = fs
        .readdirSync(migrationsDir)
        .filter((f) => f.endsWith(".sql"))
        .sort();
      for (const file of files) {
        const { rows } = await pool.query(
          "SELECT version FROM schema_migrations WHERE version = $1",
          [file]
        );
        if (rows.length === 0) {
          console.log(`[MIGRATIONS] Applying ${file}...`);
          const sql = fs.readFileSync(path.join(migrationsDir, file), "utf-8");
          await pool.query(sql);
          await pool.query("INSERT INTO schema_migrations (version) VALUES ($1)", [file]);
          console.log(`[MIGRATIONS] Applied ${file}.`);
        }
      }
    }
    console.log("[MIGRATIONS] All migrations up to date.");
  } finally {
    await pool.end();
  }
}

if (
  process.argv[1] &&
  (process.argv[1].endsWith("migrate.js") || process.argv[1].endsWith("migrate.ts"))
) {
  runMigrations().catch((err) => {
    console.error("[MIGRATIONS-ERROR]", err);
    process.exit(1);
  });
}
