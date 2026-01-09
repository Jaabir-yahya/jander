-- WaaS Core Tables (Consent, Message Logs, Audit)
-- Adds missing components for proper WaaS architecture: consent tracking, message logs, audit trail
-- 
-- Architecture: See docs/WAAS_ARCHITECTURE.md (Core Principles: Consent, Auditability)
-- Schema: See docs/WAAS_ARCHITECTURE.md (Section: Data Flow Examples)

-- Consent Table (Track opt-in, consent & trust)
CREATE TABLE consent (
  consent_id TEXT PRIMARY KEY DEFAULT 'CONS' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('consent_seq')::TEXT, 6, '0'),
  phone TEXT NOT NULL, -- Phone number is primary identifier
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms', 'ussd')),
  purpose TEXT NOT NULL CHECK (purpose IN ('transactional', 'marketing')),
  source TEXT NOT NULL, -- order_placed, ussd_menu, checkbox, qr_code, agent, web_form
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS consent_seq;

-- Message Logs (Audit trail for all messages sent)
CREATE TABLE message_logs (
  message_log_id TEXT PRIMARY KEY DEFAULT 'MSG' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('message_log_seq')::TEXT, 7, '0'),
  phone TEXT NOT NULL, -- Recipient phone number
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms', 'ussd')),
  message_type TEXT NOT NULL, -- otp, payment_confirmation, order_update, support, promotion, critical_failure
  status TEXT NOT NULL CHECK (status IN ('sent', 'delivered', 'read', 'failed', 'pending')),
  message_id TEXT, -- Provider message ID (WhatsApp message_id, SMS provider_id)
  template_name TEXT, -- WhatsApp template name (if template message)
  content_preview TEXT, -- First 200 chars of message (for audit)
  delivery_receipt_timestamp TIMESTAMPTZ, -- When delivery confirmed
  read_receipt_timestamp TIMESTAMPTZ, -- When read (if available)
  failed_reason TEXT, -- Why message failed
  fallback_used BOOLEAN DEFAULT FALSE, -- Was this a fallback message (WhatsApp → SMS)
  fallback_reason TEXT, -- Why fallback was used (timeout, failed, etc.)
  cost_kes DECIMAL, -- Cost of message (for cost tracking)
  workflow_id TEXT, -- n8n workflow ID (for tracking)
  related_entity_type TEXT, -- order, payment, conversation, etc.
  related_entity_id TEXT, -- order_id, payment_id, etc.
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS message_log_seq;

-- Audit Logs (Business actions audit trail)
CREATE TABLE audit_logs (
  audit_log_id TEXT PRIMARY KEY DEFAULT 'AUD' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('audit_log_seq')::TEXT, 7, '0'),
  entity_type TEXT NOT NULL, -- order, payment, consent, message, agent_action
  entity_id TEXT NOT NULL, -- order_id, payment_id, consent_id, etc.
  action TEXT NOT NULL, -- created, updated, deleted, confirmed, rejected, overridden
  actor_type TEXT NOT NULL CHECK (actor_type IN ('system', 'agent', 'customer', 'merchant')),
  actor_id TEXT, -- phone number, agent_id, merchant_id
  changes JSONB, -- Before/after state (for updates)
  metadata JSONB, -- Additional context (ip_address, user_agent, etc.)
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS audit_log_seq;

-- Agents Table (Human operators - future-proofing)
CREATE TABLE agents (
  agent_id TEXT PRIMARY KEY DEFAULT 'AGT' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('agent_seq')::TEXT, 5, '0'),
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL, -- Phone number as primary identifier
  email TEXT,
  merchant_id TEXT REFERENCES sellers(seller_id), -- Which merchant/outlet
  role TEXT NOT NULL CHECK (role IN ('seller', 'reviewer', 'admin', 'support')),
  permissions TEXT[], -- Array of permissions: ['view_orders', 'confirm_orders', 'override', 'view_payments']
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  last_active_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS agent_seq;

-- Merchant Outlets (Physical locations - future-proofing)
CREATE TABLE merchant_outlets (
  outlet_id TEXT PRIMARY KEY DEFAULT 'OUT' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('outlet_seq')::TEXT, 5, '0'),
  merchant_id TEXT NOT NULL REFERENCES sellers(seller_id),
  name TEXT NOT NULL, -- "Amina Fabrics - Gikomba Branch"
  market TEXT NOT NULL, -- Gikomba, Eastleigh, Toi, Wakulima
  address TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  phone TEXT, -- Outlet-specific phone
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS outlet_seq;

-- Daily Log (Disputes & manual review queue)
CREATE TABLE daily_logs (
  log_id TEXT PRIMARY KEY DEFAULT 'LOG' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('daily_log_seq')::TEXT, 6, '0'),
  date DATE DEFAULT CURRENT_DATE,
  trader_id TEXT REFERENCES sellers(seller_id),
  event_type TEXT NOT NULL, -- chat_missed, order_captured, payment_mismatch, dispute, manual_review
  details TEXT NOT NULL,
  requires_review BOOLEAN DEFAULT FALSE,
  reviewed_by TEXT REFERENCES agents(agent_id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  metadata JSONB, -- Additional context
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS daily_log_seq;

-- Indexes for Performance

-- Consent indexes
CREATE INDEX idx_consent_phone ON consent(phone);
CREATE INDEX idx_consent_channel ON consent(channel);
CREATE INDEX idx_consent_purpose ON consent(purpose);
CREATE INDEX idx_consent_status ON consent(status);
CREATE INDEX idx_consent_phone_channel ON consent(phone, channel);

-- Message Log indexes
CREATE INDEX idx_message_logs_phone ON message_logs(phone);
CREATE INDEX idx_message_logs_channel ON message_logs(channel);
CREATE INDEX idx_message_logs_message_type ON message_logs(message_type);
CREATE INDEX idx_message_logs_status ON message_logs(status);
CREATE INDEX idx_message_logs_created_at ON message_logs(created_at);
CREATE INDEX idx_message_logs_related_entity ON message_logs(related_entity_type, related_entity_id);
CREATE INDEX idx_message_logs_fallback ON message_logs(fallback_used) WHERE fallback_used = TRUE;

-- Audit Log indexes
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_type, actor_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- Agent indexes
CREATE INDEX idx_agents_phone ON agents(phone);
CREATE INDEX idx_agents_merchant_id ON agents(merchant_id);
CREATE INDEX idx_agents_role ON agents(role);
CREATE INDEX idx_agents_status ON agents(status);

-- Merchant Outlet indexes
CREATE INDEX idx_outlets_merchant_id ON merchant_outlets(merchant_id);
CREATE INDEX idx_outlets_market ON merchant_outlets(market);
CREATE INDEX idx_outlets_status ON merchant_outlets(status);

-- Daily Log indexes
CREATE INDEX idx_daily_logs_date ON daily_logs(date);
CREATE INDEX idx_daily_logs_trader_id ON daily_logs(trader_id);
CREATE INDEX idx_daily_logs_event_type ON daily_logs(event_type);
CREATE INDEX idx_daily_logs_requires_review ON daily_logs(requires_review) WHERE requires_review = TRUE;
CREATE INDEX idx_daily_logs_resolved ON daily_logs(resolved) WHERE resolved = FALSE;

-- Triggers for automatic updates
CREATE TRIGGER update_consent_updated_at BEFORE UPDATE ON consent
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_message_logs_updated_at BEFORE UPDATE ON message_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outlets_updated_at BEFORE UPDATE ON merchant_outlets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_logs_updated_at BEFORE UPDATE ON daily_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Ensure phone numbers are properly formatted (helper function)
CREATE OR REPLACE FUNCTION format_phone_number(phone TEXT)
RETURNS TEXT AS $$
BEGIN
  -- Remove all non-digits
  phone := regexp_replace(phone, '[^0-9]', '', 'g');
  
  -- If starts with 0, replace with 254
  IF phone ~ '^0' THEN
    phone := '254' || substring(phone from 2);
  END IF;
  
  -- If doesn't start with 254, add it
  IF phone !~ '^254' THEN
    phone := '254' || phone;
  END IF;
  
  RETURN '+' || phone;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Validation: Ensure phone numbers are unique across buyers/sellers/agents
-- Note: This is enforced at application level, but good to document here
-- Phone number uniqueness is critical for proper WaaS architecture

