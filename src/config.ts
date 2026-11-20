import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  host: process.env.HOST || "0.0.0.0",
  nodeEnv: process.env.NODE_ENV || "development",
  serviceName: process.env.SERVICE_NAME || "cloudops-api",
  serviceVersion: process.env.SERVICE_VERSION || "1.0.0",
  databaseUrl: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/cloudops_db",
};