-- Analytics Infrastructure Tables
-- Part of Nairobi Super Suite: Data Intelligence System
-- 
-- Architecture: See docs/core/DATA_INTELLIGENCE_SYSTEM.md
-- Provides analytics, bookkeeping, and intelligence capabilities

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Analytics Daily Summary (Materialized View)
-- Refreshed by n8n workflows for fast dashboard loading
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_daily_summary AS
SELECT 
  tenant_id,
  DATE(created_at) as date,
  COUNT(DISTINCT orders.id) as order_count,
  SUM(orders.total_amount) as revenue,
  COUNT(DISTINCT leads.id) as lead_count,
  ROUND(COUNT(DISTINCT orders.id)::decimal / NULLIF(COUNT(DISTINCT leads.id), 0) * 100, 2) as conversion_rate
FROM tenants
LEFT JOIN leads ON leads.tenant_id = tenants.id 
  AND DATE(leads.created_at) = CURRENT_DATE - INTERVAL '1 day'
LEFT JOIN orders ON orders.tenant_id = tenants.id 
  AND DATE(orders.created_at) = CURRENT_DATE - INTERVAL '1 day'
  AND orders.payment_status = 'paid'
GROUP BY tenant_id, DATE(created_at);

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_analytics_daily_summary_tenant_date 
ON analytics_daily_summary(tenant_id, date);

-- Cashbook Table
-- Tracks all income and expenses for bookkeeping
CREATE TABLE IF NOT EXISTS cashbook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  transaction_date DATE NOT NULL,
  description TEXT,
  reference TEXT, -- M-Pesa receipt, invoice number, etc
  amount DECIMAL(10,2) NOT NULL,
  type TEXT CHECK (type IN ('income', 'expense')) NOT NULL,
  category TEXT, -- 'sales', 'ad_spend', 'delivery', 'supplies'
  balance_after DECIMAL(10,2), -- Running balance
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer RFM Scores
-- Recency, Frequency, Monetary segmentation
CREATE TABLE IF NOT EXISTS customer_rfm_scores (
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  customer_phone TEXT NOT NULL,
  recency_score INT, -- Days since last order
  frequency_score INT, -- Orders in last 90 days
  monetary_score INT, -- Total spent in last 90 days
  segment TEXT, -- 'VIP', 'Loyal', 'At Risk', 'Lost'
  last_calculated TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (tenant_id, customer_phone)
);

-- Research Findings
-- Stores AI-generated insights and recommendations
CREATE TABLE IF NOT EXISTS research_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  insight_type TEXT, -- 'product_trend', 'customer_behavior', 'revenue_forecast'
  insight_text TEXT,
  confidence_score DECIMAL(3,2), -- 0.00 to 1.00
  data_points_used INT,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  action_recommendation TEXT
);

-- Full-text search indexes for orders table
-- Enable fast search across orders
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS search_vector tsvector 
GENERATED ALWAYS AS (
  setweight(to_tsvector('english', COALESCE(customer_phone, '')), 'A') ||
  setweight(to_tsvector('english', COALESCE(items::text, '')), 'B') ||
  setweight(to_tsvector('english', COALESCE(payment_status, '')), 'C')
) STORED;

CREATE INDEX IF NOT EXISTS orders_search_idx ON orders USING gin(search_vector);
CREATE INDEX IF NOT EXISTS orders_tenant_date_idx ON orders(tenant_id, created_at DESC);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_cashbook_tenant_date ON cashbook(tenant_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_cashbook_type_date ON cashbook(type, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_research_tenant_type ON research_findings(tenant_id, insight_type);
CREATE INDEX IF NOT EXISTS idx_research_tenant_generated ON research_findings(tenant_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_rfm_tenant_segment ON customer_rfm_scores(tenant_id, segment);

-- Row Level Security (RLS)
ALTER TABLE cashbook ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_rfm_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE research_findings ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Tenant Isolation
CREATE POLICY cashbook_isolation ON cashbook
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

CREATE POLICY rfm_isolation ON customer_rfm_scores
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

CREATE POLICY research_isolation ON research_findings
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

-- Function: Search Orders (Full-text search)
CREATE OR REPLACE FUNCTION search_orders(p_tenant_id UUID, query TEXT)
RETURNS TABLE (
  order_id UUID,
  customer_phone TEXT,
  total_amount DECIMAL,
  payment_status TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.customer_phone,
    o.total_amount,
    o.payment_status,
    o.created_at,
    ts_rank(o.search_vector, plainto_tsquery('english', query)) as score
  FROM orders o
  WHERE o.tenant_id = p_tenant_id
    AND o.search_vector @@ plainto_tsquery('english', query)
  ORDER BY score DESC, o.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate Running Balance for Cashbook
CREATE OR REPLACE FUNCTION calculate_cashbook_balance(p_tenant_id UUID, p_date DATE)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  v_balance DECIMAL(10,2);
BEGIN
  SELECT COALESCE(SUM(
    CASE WHEN type = 'income' THEN amount ELSE -amount END
  ), 0)
  INTO v_balance
  FROM cashbook
  WHERE tenant_id = p_tenant_id
    AND transaction_date <= p_date;
  
  RETURN v_balance;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON MATERIALIZED VIEW analytics_daily_summary IS 'Daily aggregated analytics refreshed by n8n workflows. Used for fast dashboard loading.';
COMMENT ON TABLE cashbook IS 'Complete bookkeeping ledger for income and expenses. Automatically populated by n8n workflows.';
COMMENT ON TABLE customer_rfm_scores IS 'Customer segmentation scores (Recency, Frequency, Monetary) calculated weekly.';
COMMENT ON TABLE research_findings IS 'AI-generated insights and business recommendations based on data analysis.';
COMMENT ON FUNCTION search_orders IS 'Full-text search across orders for fast information recall.';
COMMENT ON FUNCTION calculate_cashbook_balance IS 'Calculate running balance for cashbook entries up to a given date.';

