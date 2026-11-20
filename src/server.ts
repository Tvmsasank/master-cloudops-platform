import Fastify from "fastify";
import cors from "@fastify/cors";
import { config } from "./config";

const app = Fastify({
  logger: {
    level: config.nodeEnv === "production" ? "info" : "debug",
  },
});

// Enable CORS
app.register(cors, {
  origin: true,
});

// In-memory data store (will be migrated to PostgreSQL in Step 2)
interface WorkItem {
  id: string;
  title: string;
  category: string;
  createdAt: string;
}

const items: WorkItem[] = [
  {
    id: "1",
    title: "Verify zero secret leakage in git repository",
    category: "Security",
    createdAt: new Date().toISOString(),
  },
  {
    id: "2",
    title: "Setup Docker and PostgreSQL container",
    category: "DevOps",
    createdAt: new Date().toISOString(),
  },
];

// Production Health Check Endpoint (used by Kubernetes/ECS/ALB/Caddy)
app.get("/health", async (_request, reply) => {
  return reply.status(200).send({
    status: "ok",
    service: config.serviceName,
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
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

// List items
app.get("/api/v1/items", async (_request, reply) => {
  return reply.status(200).send({
    count: items.length,
    items,
  });
});

// Create item
app.post<{ Body: { title?: string; category?: string } }>("/api/v1/items", async (request, reply) => {
  const { title, category } = request.body || {};
  if (!title) {
    return reply.status(400).send({ error: "Field 'title' is required" });
  }

  const newItem: WorkItem = {
    id: String(items.length + 1),
    title,
    category: category || "General",
    createdAt: new Date().toISOString(),
  };

  items.push(newItem);
  return reply.status(201).send(newItem);
});

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

// Graceful shutdown handling (critical for Linux systemd and Docker containers)
const signals: NodeJS.Signals[] = ["SIGINT", "SIGTERM"];
for (const signal of signals) {
  process.on(signal, async () => {
    app.log.info(`Received ${signal}. Shutting down gracefully...`);
    try {
      await app.close();
      app.log.info("Server closed successfully.");
      process.exit(0);
    } catch (err) {
      app.log.error(`Error during graceful shutdown: ${err}`);
      process.exit(1);
    }
  });
}

start();