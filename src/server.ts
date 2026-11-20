import Fastify from "fastify";
import cors from "@fastify/cors";
import { config } from "./config";
import { pool, checkDatabaseHealth } from "./db";

const app = Fastify({
  logger: {
    level: config.nodeEnv === "production" ? "info" : "debug",
  },
});

app.register(cors, {
  origin: true,
});

// Production Health & Readiness Check Endpoint
app.get("/health", async (_request, reply) => {
  const dbHealth = await checkDatabaseHealth();
  const isHealthy = dbHealth.ok;

  const payload = {
    status: isHealthy ? "ok" : "degraded",
    service: config.serviceName,
    uptimeSeconds: Math.floor(process.uptime()),
    database: {
      status: isHealthy ? "connected" : "disconnected",
      latencyMs: dbHealth.latencyMs,
      error: dbHealth.error,
    },
    timestamp: new Date().toISOString(),
  };

  return reply.status(isHealthy ? 200 : 503).send(payload);
});

// Service Metadata Endpoint
app.get("/api/v1/info", async (_request, reply) => {
  return reply.status(200).send({
    service: config.serviceName,
    version: config.serviceVersion,
    environment: config.nodeEnv,
    nodeVersion: process.version,
  });
});

// List items from PostgreSQL database
app.get("/api/v1/items", async (_request, reply) => {
  try {
    const result = await pool.query(
      "SELECT id, title, category, status, created_at, updated_at FROM work_items ORDER BY id ASC"
    );
    return reply.status(200).send({
      count: result.rowCount,
      items: result.rows,
    });
  } catch (err: any) {
    app.log.error(err, "Failed to fetch work items");
    return reply.status(500).send({ error: "Database query failed", details: err.message });
  }
});

// Create item in PostgreSQL database
app.post<{ Body: { title?: string; category?: string; status?: string } }>(
  "/api/v1/items",
  async (request, reply) => {
    const { title, category, status } = request.body || {};
    if (!title) {
      return reply.status(400).send({ error: "Field 'title' is required" });
    }

    try {
      const result = await pool.query(
        "INSERT INTO work_items (title, category, status) VALUES ($1, $2, $3) RETURNING id, title, category, status, created_at, updated_at",
        [title, category || "General", status || "PENDING"]
      );
      return reply.status(201).send(result.rows[0]);
    } catch (err: any) {
      app.log.error(err, "Failed to insert work item");
      return reply.status(500).send({ error: "Failed to persist work item", details: err.message });
    }
  }
);

// Start server
const start = async () => {
  try {
    await app.listen({ port: config.port, host: config.host });
    app.log.info(`Server running at http://${config.host}:${config.port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

// Graceful shutdown handling
const signals: NodeJS.Signals[] = ["SIGINT", "SIGTERM"];
for (const signal of signals) {
  process.on(signal, async () => {
    app.log.info(`Received ${signal}. Shutting down gracefully...`);
    try {
      await app.close();
      await pool.end();
      app.log.info("Server and database pool closed successfully.");
      process.exit(0);
    } catch (err) {
      app.log.error(`Error during graceful shutdown: ${err}`);
      process.exit(1);
    }
  });
}

start();