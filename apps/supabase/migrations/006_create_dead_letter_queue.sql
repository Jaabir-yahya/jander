-- Migration 006: Create Dead Letter Queue Table
-- 
-- Purpose: Store failed operations for later retry processing
-- Architecture: Error Handling & Resilience (Phase 3)
--
-- Date: January 9, 2026
-- Reference: Week 1 Implementation Plan - Phase 3

-- ============================================
-- DEAD LETTER QUEUE TABLE
-- ============================================

CREATE TABLE dead_letter_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Operation details
  operation VARCHAR(100) NOT NULL,  -- 'send_message', 'create_invoice', 'process_payment', etc.
  payload JSONB NOT NULL,            -- Original operation payload
  
  -- Error information
  error_message TEXT,
  error_code VARCHAR(50),           -- Error classification: RETRYABLE, NEEDS_REVIEW, CRITICAL
  error_stack TEXT,                 -- Full stack trace if available
  
  -- Retry management
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 5,    -- Maximum retry attempts
  last_retry_at TIMESTAMP,
  next_retry_at TIMESTAMP,          -- When to retry next (exponential backoff)
  
  -- Status tracking
  status VARCHAR(50) DEFAULT 'pending',  -- pending, processing, resolved, failed
  resolved_at TIMESTAMP,
  resolved_by TEXT,                  -- Who/what resolved it
  
  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CHECK (retry_count >= 0),
  CHECK (retry_count <= max_retries)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Index for finding items ready to retry
CREATE INDEX idx_dlq_next_retry ON dead_letter_queue(next_retry_at, status)
WHERE status = 'pending' AND retry_count < max_retries;

-- Index for tenant-based queries
CREATE INDEX idx_dlq_tenant ON dead_letter_queue(tenant_id, status);

-- Index for operation type queries
CREATE INDEX idx_dlq_operation ON dead_letter_queue(operation, status);

-- Index for error classification
CREATE INDEX idx_dlq_error_code ON dead_letter_queue(error_code, status);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_dlq_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dlq_updated_at
  BEFORE UPDATE ON dead_letter_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_dlq_updated_at();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to calculate next retry time (exponential backoff)
CREATE OR REPLACE FUNCTION calculate_next_retry_time(
  retry_count INTEGER,
  base_delay_seconds INTEGER DEFAULT 60
)
RETURNS TIMESTAMP AS $$
BEGIN
  -- Exponential backoff: base_delay * 2^retry_count
  -- With jitter: add random 0-10% of delay
  -- Max delay: 1 hour
  DECLARE
    delay_seconds INTEGER;
    jitter_seconds INTEGER;
    total_delay INTEGER;
  BEGIN
    delay_seconds := base_delay_seconds * POWER(2, retry_count);
    delay_seconds := LEAST(delay_seconds, 3600); -- Cap at 1 hour
    jitter_seconds := FLOOR(RANDOM() * delay_seconds * 0.1); -- 0-10% jitter
    total_delay := delay_seconds + jitter_seconds;
    
    RETURN NOW() + (total_delay || ' seconds')::INTERVAL;
  END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_next_retry_time(INTEGER, INTEGER) IS 'Calculate next retry time using exponential backoff with jitter. Returns timestamp for next_retry_at.';

-- Function to get items ready for retry
CREATE OR REPLACE FUNCTION get_dlq_items_ready_for_retry(
  batch_size INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  tenant_id UUID,
  operation VARCHAR,
  payload JSONB,
  retry_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dlq.id,
    dlq.tenant_id,
    dlq.operation,
    dlq.payload,
    dlq.retry_count
  FROM dead_letter_queue dlq
  WHERE dlq.status = 'pending'
    AND dlq.retry_count < dlq.max_retries
    AND (dlq.next_retry_at IS NULL OR dlq.next_retry_at <= NOW())
  ORDER BY dlq.created_at ASC
  LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_dlq_items_ready_for_retry(INTEGER) IS 'Get dead letter queue items ready for retry processing. Returns batch of items ordered by creation time.';

-- Function to mark item as processing
CREATE OR REPLACE FUNCTION mark_dlq_processing(item_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE dead_letter_queue
  SET status = 'processing',
      updated_at = NOW()
  WHERE id = item_id
    AND status = 'pending';
END;
$$ LANGUAGE plpgsql;

-- Function to mark item as resolved
CREATE OR REPLACE FUNCTION mark_dlq_resolved(
  item_id UUID,
  resolved_by TEXT DEFAULT 'system'
)
RETURNS VOID AS $$
BEGIN
  UPDATE dead_letter_queue
  SET status = 'resolved',
      resolved_at = NOW(),
      resolved_by = resolved_by,
      updated_at = NOW()
  WHERE id = item_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment retry count and schedule next retry
CREATE OR REPLACE FUNCTION increment_dlq_retry(
  item_id UUID,
  error_message TEXT DEFAULT NULL,
  error_code VARCHAR(50) DEFAULT 'RETRYABLE'
)
RETURNS VOID AS $$
DECLARE
  current_retry_count INTEGER;
  current_max_retries INTEGER;
BEGIN
  SELECT retry_count, max_retries
  INTO current_retry_count, current_max_retries
  FROM dead_letter_queue
  WHERE id = item_id;
  
  IF current_retry_count >= current_max_retries THEN
    -- Max retries reached, mark as failed
    UPDATE dead_letter_queue
    SET status = 'failed',
        error_message = COALESCE(error_message, dead_letter_queue.error_message),
        error_code = COALESCE(error_code, dead_letter_queue.error_code),
        updated_at = NOW()
    WHERE id = item_id;
  ELSE
    -- Increment retry and schedule next attempt
    UPDATE dead_letter_queue
    SET retry_count = retry_count + 1,
        last_retry_at = NOW(),
        next_retry_at = calculate_next_retry_time(retry_count + 1),
        status = 'pending',
        error_message = COALESCE(error_message, dead_letter_queue.error_message),
        error_code = COALESCE(error_code, dead_letter_queue.error_code),
        updated_at = NOW()
    WHERE id = item_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE dead_letter_queue ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own tenant's dead letter queue items
CREATE POLICY dlq_tenant_isolation ON dead_letter_queue
  FOR SELECT
  USING (
    -- For now, allow all reads (adjust based on your auth system)
    -- In production: tenant_id = current_setting('app.current_tenant_id', true)::uuid
    true
  );

-- Policy: Users can only insert for their own tenant
CREATE POLICY dlq_tenant_insert ON dead_letter_queue
  FOR INSERT
  WITH CHECK (
    -- In production: tenant_id = current_setting('app.current_tenant_id', true)::uuid
    true
  );

-- Policy: Users can only update their own tenant's items
CREATE POLICY dlq_tenant_update ON dead_letter_queue
  FOR UPDATE
  USING (
    -- In production: tenant_id = current_setting('app.current_tenant_id', true)::uuid
    true
  );

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE dead_letter_queue IS 'Dead letter queue for failed operations. Stores operations that failed and need retry or manual review.';
COMMENT ON COLUMN dead_letter_queue.operation IS 'Operation type: send_message, create_invoice, process_payment, etc.';
COMMENT ON COLUMN dead_letter_queue.payload IS 'Original operation payload (JSONB) for retry';
COMMENT ON COLUMN dead_letter_queue.error_code IS 'Error classification: RETRYABLE (can retry), NEEDS_REVIEW (manual intervention), CRITICAL (escalate)';
COMMENT ON COLUMN dead_letter_queue.next_retry_at IS 'Timestamp for next retry attempt (exponential backoff)';

