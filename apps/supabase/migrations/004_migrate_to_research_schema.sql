-- Migration 004: Full Migration to Research-Backed Architecture
-- 
-- This migration replaces the trade facilitator schema (buyers/sellers/trades)
-- with the research-locked schema from docs/core/verified-research-findings.md
--
-- Status: LOCKED - Based on validated patterns from India, Brazil, Nigeria production systems
-- Date: January 9, 2026
--
-- Reference: docs/core/verified-research-findings.md PART 2: DATABASE LAYER

-- ============================================
-- STEP 1: DROP OLD SCHEMA (Safe on Day 2 - no production data)
-- ============================================

-- Drop old tables in reverse dependency order
DROP TABLE IF EXISTS daily_logs CASCADE;
DROP TABLE IF EXISTS merchant_outlets CASCADE;
DROP TABLE IF EXISTS agents CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS message_logs CASCADE;
DROP TABLE IF EXISTS consent CASCADE;
DROP TABLE IF EXISTS payouts CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS trades CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS buyers CASCADE;

-- Drop old sequences
DROP SEQUENCE IF EXISTS buyer_seq;
DROP SEQUENCE IF EXISTS seller_seq;
DROP SEQUENCE IF EXISTS product_seq;
DROP SEQUENCE IF EXISTS trade_seq;

-- ============================================
-- STEP 2: CREATE RESEARCH-LOCKED SCHEMA
-- ============================================

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TENANTS (Root isolation unit)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE,                      -- Primary trader phone
    is_active BOOLEAN DEFAULT true,
    m_pesa_paybill VARCHAR(20),
    whatsapp_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tenants_phone ON tenants(phone);
CREATE INDEX idx_tenants_active ON tenants(is_active);

-- ORDERS (Core transaction record)
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    order_number VARCHAR(50) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    items JSONB NOT NULL,                          -- [{name, qty, price}]
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',          -- pending, paid, shipped, delivered
    payment_status VARCHAR(50) DEFAULT 'unpaid',   -- unpaid, initiated, paid, failed
    
    -- M-Pesa reconciliation fields
    m_pesa_receipt VARCHAR(50) UNIQUE,             -- GLOBAL unique receipt
    m_pesa_initiated_at TIMESTAMP,
    m_pesa_paid_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(tenant_id, order_number),               -- Per-tenant order numbers
    CHECK (total_amount > 0)
);

CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status);
CREATE INDEX idx_orders_tenant_created ON orders(tenant_id, created_at DESC);
CREATE INDEX idx_orders_payment_status ON orders(tenant_id, payment_status);
CREATE INDEX idx_orders_customer_phone ON orders(tenant_id, customer_phone);

-- PAYMENTS (Payment reconciliation record - CRITICAL)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    
    -- M-Pesa source
    m_pesa_receipt VARCHAR(50) NOT NULL,
    m_pesa_phone VARCHAR(20) NOT NULL,
    m_pesa_amount DECIMAL(10,2) NOT NULL,
    m_pesa_timestamp TIMESTAMP NOT NULL,
    m_pesa_mpesa_code VARCHAR(50),                 -- Transaction reference
    
    -- Matching result
    order_id UUID REFERENCES orders(id),           -- NULL if unmatched
    match_confidence DECIMAL(3,2),                 -- 0.0-1.0 (0.95+ auto-matched)
    match_method VARCHAR(50),                      -- 'exact_phone_amount', 'fuzzy_amount_tolerance', 'manual'
    match_notes TEXT,
    
    status VARCHAR(50) DEFAULT 'received',         -- received, matched, reconciled, disputed
    webhook_id VARCHAR(100) UNIQUE NOT NULL,       -- Idempotency key for M-Pesa callback
    received_at TIMESTAMP DEFAULT NOW(),
    reconciled_at TIMESTAMP,
    
    UNIQUE(tenant_id, webhook_id)                  -- Prevent duplicate webhook processing
);

CREATE INDEX idx_payments_tenant_status ON payments(tenant_id, status);
CREATE INDEX idx_payments_m_pesa_receipt ON payments(m_pesa_receipt);
CREATE INDEX idx_payments_webhook_id ON payments(webhook_id);
CREATE INDEX idx_payments_unmatched ON payments(tenant_id, order_id) WHERE order_id IS NULL;

-- MESSAGES (WhatsApp conversation history)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    customer_phone VARCHAR(20) NOT NULL,
    direction VARCHAR(20) NOT NULL,               -- 'inbound' or 'outbound'
    message_type VARCHAR(50),                      -- 'text', 'image', 'voice', 'document'
    content TEXT,
    
    -- WhatsApp metadata
    whatsapp_message_id VARCHAR(100) UNIQUE,
    whatsapp_timestamp TIMESTAMP,
    
    -- Intent classification (set by workflow)
    intent VARCHAR(50),                            -- 'order', 'payment', 'inquiry', 'unknown'
    confidence DECIMAL(3,2),
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_tenant_customer ON messages(tenant_id, customer_phone);
CREATE INDEX idx_messages_intent ON messages(tenant_id, intent);

-- REVIEW_QUEUE (Human-in-the-loop for edge cases)
CREATE TABLE review_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    item_type VARCHAR(50) NOT NULL,               -- 'payment_mismatch', 'low_confidence_order'
    reference_id UUID,                             -- payment.id or order.id
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',         -- pending, reviewed, resolved
    reviewer_notes TEXT,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_review_queue_tenant_status ON review_queue(tenant_id, status);
CREATE INDEX idx_review_queue_created ON review_queue(tenant_id, created_at DESC);

-- WEBHOOK_RECEIVED (Idempotency tracking - CRITICAL for M-Pesa webhooks)
CREATE TABLE webhook_received (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    webhook_id VARCHAR(100) NOT NULL,             -- Unique webhook identifier from M-Pesa/WhatsApp
    status VARCHAR(20) DEFAULT 'pending',         -- pending, processed, failed
    payload JSONB,                                 -- Store original webhook payload for debugging
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP,
    
    UNIQUE(tenant_id, webhook_id)                 -- Prevent duplicate webhook processing
);

CREATE INDEX idx_webhook_received_tenant_status ON webhook_received(tenant_id, status);
CREATE INDEX idx_webhook_received_webhook_id ON webhook_received(webhook_id);

-- ============================================
-- STEP 3: ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Helper function: Get current tenant_id from JWT
CREATE OR REPLACE FUNCTION auth.current_tenant_id() 
RETURNS UUID AS $$
  SELECT (auth.jwt() ->> 'tenant_id')::UUID;
$$ LANGUAGE sql STABLE;

-- ORDERS RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access orders from their tenant"
ON orders FOR ALL
TO authenticated
USING (tenant_id = auth.current_tenant_id())
WITH CHECK (tenant_id = auth.current_tenant_id());

-- PAYMENTS RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access payments from their tenant"
ON payments FOR ALL
TO authenticated
USING (tenant_id = auth.current_tenant_id())
WITH CHECK (tenant_id = auth.current_tenant_id());

-- MESSAGES RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access messages from their tenant"
ON messages FOR ALL
TO authenticated
USING (tenant_id = auth.current_tenant_id())
WITH CHECK (tenant_id = auth.current_tenant_id());

-- REVIEW_QUEUE RLS
ALTER TABLE review_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access review queue for their tenant"
ON review_queue FOR ALL
TO authenticated
USING (tenant_id = auth.current_tenant_id())
WITH CHECK (tenant_id = auth.current_tenant_id());

-- WEBHOOK_RECEIVED RLS
ALTER TABLE webhook_received ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access webhook_received from their tenant"
ON webhook_received FOR ALL
TO authenticated
USING (tenant_id = auth.current_tenant_id())
WITH CHECK (tenant_id = auth.current_tenant_id());

-- TENANTS RLS (Allow read-only access to own tenant metadata)
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own tenant"
ON tenants FOR SELECT
TO authenticated
USING (id = auth.current_tenant_id());

-- ============================================
-- STEP 4: PAYMENT MATCHING FUNCTIONS
-- ============================================

-- TIER 1: EXACT MATCH (Instant auto-approve)
-- Phone + Amount (exact match)
CREATE OR REPLACE FUNCTION match_payment_exact(
    p_tenant_id UUID,
    p_phone VARCHAR,
    p_amount DECIMAL,
    p_m_pesa_receipt VARCHAR
) RETURNS TABLE(order_id UUID, confidence DECIMAL) AS $$
SELECT 
    o.id,
    1.0::DECIMAL as confidence
FROM orders o
WHERE 
    o.tenant_id = p_tenant_id
    AND o.customer_phone = p_phone
    AND o.total_amount = p_amount
    AND o.payment_status = 'unpaid'
    AND o.created_at > NOW() - INTERVAL '24 hours'  -- Only recent orders
LIMIT 1;
$$ LANGUAGE sql STABLE;

-- TIER 2: FUZZY MATCH (Amount tolerance)
-- Phone + Amount (±KSh 20 tolerance) - handles rounding errors, fees
CREATE OR REPLACE FUNCTION match_payment_fuzzy(
    p_tenant_id UUID,
    p_phone VARCHAR,
    p_amount DECIMAL
) RETURNS TABLE(order_id UUID, confidence DECIMAL) AS $$
SELECT 
    o.id,
    (1.0 - ABS(o.total_amount - p_amount) / NULLIF(p_amount, 0))::DECIMAL as confidence
FROM orders o
WHERE 
    o.tenant_id = p_tenant_id
    AND o.customer_phone = p_phone
    AND ABS(o.total_amount - p_amount) <= 20        -- KSh 20 tolerance
    AND o.payment_status = 'unpaid'
    AND o.created_at > NOW() - INTERVAL '48 hours'
ORDER BY confidence DESC
LIMIT 1;
$$ LANGUAGE sql STABLE;

-- TIER 3: HUMAN REVIEW (Low confidence or no match)
-- Create review queue entry for human assessment
CREATE OR REPLACE FUNCTION queue_payment_review(
    p_tenant_id UUID,
    p_payment_id UUID,
    p_reason TEXT
) RETURNS void AS $$
INSERT INTO review_queue (tenant_id, item_type, reference_id, reason)
VALUES (p_tenant_id, 'payment_mismatch', p_payment_id, p_reason);
$$ LANGUAGE sql;

-- ============================================
-- STEP 5: SEED TEST DATA
-- ============================================

-- Insert 3 test tenants for development/testing
INSERT INTO tenants (name, phone, whatsapp_number, m_pesa_paybill, is_active) VALUES
('Test Trader 1', '+254700123456', '+254700123456', '12345', true),
('Test Trader 2', '+254700789012', '+254700789012', '67890', true),
('Test Trader 3', '+254700345678', '+254700345678', '11111', true)
ON CONFLICT (phone) DO NOTHING;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Verify tables created
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('tenants', 'orders', 'payments', 'messages', 'review_queue', 'webhook_received');
    
    IF table_count = 6 THEN
        RAISE NOTICE '✅ Migration successful: All 6 research-locked tables created';
    ELSE
        RAISE EXCEPTION '❌ Migration failed: Expected 6 tables, found %', table_count;
    END IF;
END $$;

