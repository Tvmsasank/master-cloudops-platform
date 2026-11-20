# CloudOps Production Platform

A production-grade microservice platform engineered for modern DevOps, Cloud, and SRE workflows.

## Architecture & Roadmap
- [x] **Phase 1: Foundation & Security** (TypeScript REST API, Fastify, strict secret exclusion, graceful signal handling)
- [ ] **Phase 2: Data Persistence & DR** (PostgreSQL, schema migrations, automated `pg_dump` & point-in-time restore drills)
- [ ] **Phase 3: Containerization** (Multi-stage Dockerfile, Docker Compose bridge networks, named persistent volumes)
- [ ] **Phase 4: Linux & Server Operations** (Systemd service management, process controls, journald log aggregation)
- [ ] **Phase 5: AWS Cloud Infrastructure** (EC2, KMS encryption, private S3 backup buckets, IAM Instance Profiles)
- [ ] **Phase 6: HTTPS & Reverse Proxy** (Caddy reverse proxy with automated TLS/Let's Encrypt certificates)
- [ ] **Phase 7: Automation & CI/CD** (GitHub Actions build/test pipelines, Terraform Infrastructure as Code)
- [ ] **Phase 8: Enterprise Governance & Operations** (GRC compliance matrices, ITSM incident & change management runbooks)

## Quickstart (Local Development)

### 1. Install dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` (Never commit `.env` to version control!):
```bash
cp .env.example .env
```

### 3. Build & Run
```bash
# Build TypeScript
npm run build

# Start production server
npm start

# Or start in hot-reload dev mode
npm run dev
```

### 4. Health Check
```bash
curl http://localhost:3000/health
```