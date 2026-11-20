-- CloudOps Platform Database Initialization Script
-- Executed on container creation when volume is first mounted

CREATE TABLE IF NOT EXISTS work_items (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'General',
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes to optimize filtering by category and status
CREATE INDEX IF NOT EXISTS idx_work_items_category ON work_items(category);
CREATE INDEX IF NOT EXISTS idx_work_items_status ON work_items(status);

-- Seed initial production tasks
INSERT INTO work_items (title, category, status) VALUES
('Implement zero secret leakage policy in git', 'Security', 'COMPLETED'),
('Containerize Node.js API with multi-stage Dockerfile', 'DevOps', 'IN_PROGRESS'),
('Automate PostgreSQL backup and disaster recovery drill', 'Database', 'IN_PROGRESS'),
('Configure AWS IAM Instance Profile instead of access keys', 'Cloud', 'PENDING');