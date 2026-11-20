import pg from "pg";
import { config } from "./config";

const { Pool } = pg;

export const pool = new Pool({
  connectionString: config.databaseUrl,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on("error", (err) => {
  console.error("Unexpected error on idle PostgreSQL client", err);
});

export async function checkDatabaseHealth(): Promise<{ ok: boolean; error?: string; latencyMs?: number }> {
  const start = Date.now();
  try {
    const res = await pool.query("SELECT 1 AS health");
    const latencyMs = Date.now() - start;
    if (res.rows[0]?.health === 1) {
      return { ok: true, latencyMs };
    }
    return { ok: false, error: "Unexpected database response" };
  } catch (err: any) {
    return { ok: false, error: err.message };
  }
}