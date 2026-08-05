import { Pool } from "pg";

export function createDatabasePool(connectionString?: string): Pool {
  const url =
    connectionString ||
    process.env.DATABASE_URL ||
    "postgresql://guffsuff_user:guffsuff_local_pass@localhost:5432/guffsuff_dev";
  return new Pool({
    connectionString: url,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000
  });
}
