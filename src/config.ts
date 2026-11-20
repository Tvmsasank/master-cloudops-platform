import dotenv from "dotenv";

// Load environment variables from .env
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  host: process.env.HOST || "0.0.0.0",
  nodeEnv: process.env.NODE_ENV || "development",
  serviceName: process.env.SERVICE_NAME || "cloudops-api",
  serviceVersion: process.env.SERVICE_VERSION || "1.0.0",
};