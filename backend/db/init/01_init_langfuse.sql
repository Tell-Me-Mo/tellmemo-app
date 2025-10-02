-- Initialize Langfuse database
-- This script runs when PostgreSQL container starts for the first time

-- Create Langfuse database if it doesn't exist
SELECT 'CREATE DATABASE langfuse_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'langfuse_db')\gexec

-- Grant all privileges to the main user
GRANT ALL PRIVILEGES ON DATABASE langfuse_db TO pm_master;