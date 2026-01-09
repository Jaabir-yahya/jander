-- Tenant Configuration Table
-- Multi-tenant support for Nairobi SMEs (one WABA per SME model)
-- 
-- Architecture: See docs/NATIVE_INTEGRATIONS.md (Multi-tenant wiring)
-- Each SME has their own WABA, ERPNext instance, M-Pesa shortcode, tax config
--
-- Reference: See docs/WAAS_ARCHITECTURE.md (Layer 1: System of Record)

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tenant Configuration Table
-- Stores per-SME configuration for all integrations
CREATE TABLE tenant_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id TEXT UNIQUE NOT NULL, -- e.g., "sme_001", "nairobi_boutique"
  tenant_name TEXT NOT NULL, -- Display name: "Nairobi Boutique"
  status TEXT DEFAULT 'active', -- active, suspended, inactive
  
  -- WhatsApp Business Account (WABA) Configuration
  waba_phone_number_id TEXT, -- Meta Phone Number ID
  waba_access_token TEXT, -- WhatsApp Business API access token
  waba_provider TEXT DEFAULT 'smsleopard', -- smsleopard or meta
  smsleopard_token TEXT, -- SMSLeopard API token (if using SMSLeopard)
  
  -- ERPNext Configuration
  erp_base_url TEXT, -- e.g., "https://erp.sme.com" or "https://sme.erpnext.com"
  erp_company_name TEXT, -- Company name in ERPNext
  erp_api_key TEXT, -- ERPNext API key
  erp_api_secret TEXT, -- ERPNext API secret
  
  -- M-Pesa Configuration
  mpesa_shortcode TEXT, -- Till/Paybill number
  mpesa_passkey TEXT, -- M-Pesa passkey
  mpesa_consumer_key TEXT, -- Daraja consumer key
  mpesa_consumer_secret TEXT, -- Daraja consumer secret
  mpesa_initiator_name TEXT, -- For B2C payouts
  mpesa_security_credential TEXT, -- For B2C payouts
  
  -- Payment Rails Configuration (JSONB for flexibility)
  -- Format: [{"rail_type": "mpesa", "shortcode": "123456", "enabled": true, "priority": 1}, ...]
  payment_rails JSONB DEFAULT '[]'::jsonb,
  
  -- Tax System Configuration (JSONB for flexibility)
  -- Format: {"system": "etims", "pin": "A000000000", "oscu_endpoint": "https://...", "api_key": "...", "api_secret": "..."}
  tax_system JSONB DEFAULT '{}'::jsonb,
  
  -- SMS Fallback Configuration
  sms_provider TEXT DEFAULT 'smsleopard', -- smsleopard or africastalking
  sms_api_key TEXT, -- SMS provider API key
  sms_sender_id TEXT, -- Registered sender ID
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT, -- User who created this tenant
  notes TEXT -- Internal notes
);

-- Create indexes for fast lookups
CREATE INDEX idx_tenant_config_tenant_id ON tenant_config(tenant_id);
CREATE INDEX idx_tenant_config_status ON tenant_config(status);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_tenant_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tenant_config_updated_at
  BEFORE UPDATE ON tenant_config
  FOR EACH ROW
  EXECUTE FUNCTION update_tenant_config_updated_at();

-- Add tenant_id to existing tables for multi-tenant support
-- Note: This is optional - only add if you want to migrate existing data
-- For new deployments, tenant_id should be added from the start

-- Example: Add tenant_id to trades table (if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'trades' AND column_name = 'tenant_id'
  ) THEN
    ALTER TABLE trades ADD COLUMN tenant_id TEXT;
    CREATE INDEX idx_trades_tenant_id ON trades(tenant_id);
  END IF;
END $$;

-- Example: Add tenant_id to orders table (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'orders'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'orders' AND column_name = 'tenant_id'
    ) THEN
      ALTER TABLE orders ADD COLUMN tenant_id TEXT;
      CREATE INDEX idx_orders_tenant_id ON orders(tenant_id);
    END IF;
  END IF;
END $$;

-- Example: Add tenant_id to payments table (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'payments'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'payments' AND column_name = 'tenant_id'
    ) THEN
      ALTER TABLE payments ADD COLUMN tenant_id TEXT;
      CREATE INDEX idx_payments_tenant_id ON payments(tenant_id);
    END IF;
  END IF;
END $$;

-- Row Level Security (RLS) for multi-tenant isolation
-- Enable RLS on tenant_config
ALTER TABLE tenant_config ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own tenant config
-- Note: Adjust this policy based on your authentication setup
CREATE POLICY tenant_config_isolation ON tenant_config
  USING (
    -- For now, allow all reads (adjust based on your auth system)
    -- In production, use: tenant_id = current_setting('app.current_tenant_id', true)
    true
  );

-- Insert sample tenant config (for testing)
-- Remove this in production or make it conditional
INSERT INTO tenant_config (
  tenant_id,
  tenant_name,
  waba_phone_number_id,
  waba_provider,
  erp_base_url,
  erp_company_name,
  mpesa_shortcode,
  payment_rails,
  tax_system
) VALUES (
  'sme_001',
  'Nairobi Boutique',
  'PHONE_NUMBER_ID_HERE',
  'smsleopard',
  'https://erp.nairobi-boutique.com',
  'Nairobi Boutique Ltd',
  '123456',
  '[
    {
      "rail_type": "mpesa",
      "shortcode": "123456",
      "enabled": true,
      "priority": 1
    },
    {
      "rail_type": "pesalink",
      "account_number": "01234567890",
      "enabled": false,
      "priority": 2
    },
    {
      "rail_type": "airtel_money",
      "merchant_code": "AIRTEL001",
      "enabled": false,
      "priority": 3
    }
  ]'::jsonb,
  '{
    "system": "etims",
    "pin": "A000000000",
    "oscu_endpoint": "https://api.kra.go.ke/etims/oscu",
    "api_key": "API_KEY_HERE",
    "api_secret": "API_SECRET_HERE"
  }'::jsonb
) ON CONFLICT (tenant_id) DO NOTHING;

-- Comments for documentation
COMMENT ON TABLE tenant_config IS 'Multi-tenant configuration for Nairobi SMEs. Each tenant (SME) has their own WABA, ERPNext, M-Pesa, and tax system config.';
COMMENT ON COLUMN tenant_config.tenant_id IS 'Unique tenant identifier (e.g., sme_001, nairobi_boutique)';
COMMENT ON COLUMN tenant_config.payment_rails IS 'JSONB array of payment rails with priority and enabled status';
COMMENT ON COLUMN tenant_config.tax_system IS 'JSONB object with tax system configuration (eTIMS/KRA)';

