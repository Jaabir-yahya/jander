-- Support Infrastructure Tables
-- Part of Nairobi Super Suite: Production Blueprint
-- 
-- Architecture: See docs/core/PRODUCTION_BLUEPRINT.md
-- Provides emergency controls, support case tracking, manual entry handling

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Support Cases Table
-- Tracks all support issues, escalations, and resolutions
CREATE TABLE IF NOT EXISTS support_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  case_type TEXT CHECK (case_type IN ('payment_issue', 'api_down', 'customer_complaint', 'technical_issue', 'onboarding', 'billing')) NOT NULL,
  priority TEXT CHECK (priority IN ('critical', 'high', 'medium', 'low')) DEFAULT 'medium',
  status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'escalated', 'closed')) DEFAULT 'open',
  automated BOOLEAN DEFAULT FALSE, -- Was this created by automation or manually?
  assigned_to TEXT, -- WhatsApp number or 'system' or NULL
  description TEXT,
  resolution_notes TEXT,
  resolution_time INTERVAL, -- Time from open to resolved
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Manual Entries Table
-- For cash sales, manual reconciliations, adjustments
CREATE TABLE IF NOT EXISTS manual_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  entry_date DATE DEFAULT CURRENT_DATE,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  entry_type TEXT CHECK (entry_type IN ('sale', 'expense', 'payment', 'adjustment', 'refund')) NOT NULL,
  reference TEXT, -- M-Pesa receipt, invoice number, etc
  reconciled BOOLEAN DEFAULT FALSE,
  reconciled_with_order_id UUID REFERENCES orders(id),
  entered_by TEXT, -- Staff WhatsApp for audit trail
  metadata JSONB DEFAULT '{}'::jsonb, -- Additional flexible data
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tenant Automation Control
-- Emergency pause mechanism for tenant automation
CREATE TABLE IF NOT EXISTS tenant_automation_control (
  tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
  automation_paused BOOLEAN DEFAULT FALSE,
  pause_reason TEXT,
  paused_at TIMESTAMPTZ,
  paused_by TEXT, -- Who paused it (WhatsApp number or 'system')
  fallback_mode TEXT CHECK (fallback_mode IN ('sms', 'manual', 'none')) DEFAULT 'sms',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Health Check Logs
-- System-wide and tenant-specific health monitoring
CREATE TABLE IF NOT EXISTS health_check_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL for system-wide checks
  check_type TEXT NOT NULL, -- 'instagram_api', 'whatsapp_api', 'mpesa_api', 'database', 'workflow', 'supabase'
  status TEXT CHECK (status IN ('healthy', 'degraded', 'down', 'unknown')) DEFAULT 'healthy',
  response_time_ms INT,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb, -- Additional check details
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_support_cases_tenant_status ON support_cases(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_support_cases_priority ON support_cases(priority, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_cases_type ON support_cases(case_type, status);
CREATE INDEX IF NOT EXISTS idx_manual_entries_tenant_date ON manual_entries(tenant_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_manual_entries_reconciled ON manual_entries(reconciled, tenant_id);
CREATE INDEX IF NOT EXISTS idx_manual_entries_type ON manual_entries(entry_type, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_health_check_type_time ON health_check_logs(check_type, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_check_tenant ON health_check_logs(tenant_id, checked_at DESC) WHERE tenant_id IS NOT NULL;

-- Functions
CREATE OR REPLACE FUNCTION update_support_cases_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_automation_control_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER support_cases_updated_at
  BEFORE UPDATE ON support_cases
  FOR EACH ROW
  EXECUTE FUNCTION update_support_cases_updated_at();

CREATE TRIGGER automation_control_updated_at
  BEFORE UPDATE ON tenant_automation_control
  FOR EACH ROW
  EXECUTE FUNCTION update_automation_control_updated_at();

-- Function: Calculate resolution time when case is resolved
CREATE OR REPLACE FUNCTION calculate_support_case_resolution_time()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
    NEW.resolved_at = NOW();
    NEW.resolution_time = NOW() - NEW.created_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER support_cases_resolution_time
  BEFORE UPDATE ON support_cases
  FOR EACH ROW
  EXECUTE FUNCTION calculate_support_case_resolution_time();

-- Row Level Security (RLS)
ALTER TABLE support_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_automation_control ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_check_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Tenant Isolation
CREATE POLICY support_cases_isolation ON support_cases
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

CREATE POLICY manual_entries_isolation ON manual_entries
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

CREATE POLICY automation_control_isolation ON tenant_automation_control
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

-- Health check logs: System-wide checks visible to all, tenant-specific checks isolated
CREATE POLICY health_check_logs_isolation ON health_check_logs
  FOR ALL
  USING (
    tenant_id IS NULL -- System-wide checks visible to all
    OR tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

-- Comments
COMMENT ON TABLE support_cases IS 'Tracks all support issues, escalations, and resolutions. Used for SLA tracking and operational monitoring.';
COMMENT ON TABLE manual_entries IS 'Manual entries for cash sales, adjustments, and manual reconciliations. Critical for Nairobi SMEs who handle cash transactions.';
COMMENT ON TABLE tenant_automation_control IS 'Emergency pause mechanism for tenant automation. Allows graceful degradation when APIs fail.';
COMMENT ON TABLE health_check_logs IS 'System-wide and tenant-specific health monitoring. Used for proactive alerting and incident response.';

COMMENT ON COLUMN support_cases.automated IS 'Whether this case was created automatically by system or manually by staff';
COMMENT ON COLUMN support_cases.resolution_time IS 'Automatically calculated when case is resolved';
COMMENT ON COLUMN manual_entries.entered_by IS 'WhatsApp number of staff member who entered this (for audit trail)';
COMMENT ON COLUMN tenant_automation_control.fallback_mode IS 'What mode to use when automation is paused: sms, manual, or none';

