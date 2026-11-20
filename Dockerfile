# ==========================================
# Stage 1: Build & Compile TypeScript
# ==========================================
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package manifests first to leverage Docker layer caching
COPY package*.json ./
RUN npm ci

# Copy configuration and TypeScript sources
COPY tsconfig.json ./
COPY src/ ./src/

# Compile TypeScript to JavaScript in /app/dist
RUN npm run build

# ==========================================
# Stage 2: Minimal Production Runtime
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Install only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled JavaScript from builder stage
COPY --from=builder /app/dist ./dist

# Security Hardening: Run as unprivileged node user (non-root)
USER node

# Expose API port
EXPOSE 3000

# Start production server
CMD ["node", "dist/server.js"]