-- Migration 007: Create Error Logs Table
-- 
-- Purpose: Store error logs from structured logging utility
-- Architecture: Monitoring & Logging (Phase 4)
--
-- Date: January 9, 2026
-- Reference: Week 1 Implementation Plan - Phase 4

-- ============================================
-- ERROR LOGS TABLE
-- ============================================

CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
  
  -- Service information
  service VARCHAR(100) NOT NULL,  -- 'whatsapp-business', 'n8n', etc.
  environment VARCHAR(50),         -- 'development', 'staging', 'production'
  
  -- Error details
  error_message TEXT NOT NULL,
  error_code VARCHAR(50),         -- Error classification code
  error_stack TEXT,                -- Full stack trace
  
  -- Context
  context JSONB DEFAULT '{}'::jsonb,  -- Additional context from log entry
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Index for service-based queries
CREATE INDEX idx_error_logs_service ON error_logs(service, created_at DESC);

-- Index for tenant-based queries
CREATE INDEX idx_error_logs_tenant ON error_logs(tenant_id, created_at DESC)
WHERE tenant_id IS NOT NULL;

-- Index for error code queries
CREATE INDEX idx_error_logs_code ON error_logs(error_code, created_at DESC)
WHERE error_code IS NOT NULL;

-- Index for time-based queries (cleanup old logs)
CREATE INDEX idx_error_logs_created ON error_logs(created_at);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own tenant's error logs
CREATE POLICY error_logs_tenant_isolation ON error_logs
  FOR SELECT
  USING (
    -- For now, allow all reads (adjust based on your auth system)
    -- In production: tenant_id = current_setting('app.current_tenant_id', true)::uuid
    true
  );

-- ============================================
-- CLEANUP FUNCTION (Optional - for log retention)
-- ============================================

-- Function to delete old error logs (older than retention_days)
CREATE OR REPLACE FUNCTION cleanup_old_error_logs(retention_days INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM error_logs
  WHERE created_at < NOW() - (retention_days || ' days')::INTERVAL;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_error_logs(INTEGER) IS 'Delete error logs older than retention_days. Returns count of deleted records.';

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE error_logs IS 'Error logs from structured logging utility. Stores errors for monitoring and debugging.';
COMMENT ON COLUMN error_logs.service IS 'Service name that generated the error (whatsapp-business, n8n, etc.)';
COMMENT ON COLUMN error_logs.context IS 'Additional context from log entry (JSONB)';

