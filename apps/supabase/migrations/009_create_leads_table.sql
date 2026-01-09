-- Leads Table: Instagram Lead Generation
-- Part of Nairobi Super Suite: Instagram Reels → WhatsApp Orders → M-Pesa Payments
-- 
-- Architecture: See docs/core/NAIROBI_SUPER_SUITE_EXPANSION.md
-- Tracks leads from Instagram comments, DMs, and other sources
-- Enables attribution: Campaign → Lead → Order → Revenue

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Leads Table
-- Stores leads captured from Instagram and other sources
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Source tracking
  source TEXT NOT NULL DEFAULT 'instagram', -- instagram, facebook, organic, referral
  source_detail TEXT, -- e.g., "instagram_comment", "instagram_dm", "reels_view"
  
  -- Instagram-specific data
  instagram_user_id TEXT, -- Instagram user ID (from Graph API)
  instagram_username TEXT, -- Instagram username (if available)
  reel_id TEXT, -- Instagram Reel/Media ID that triggered the lead
  reel_permalink TEXT, -- URL to the Reel
  comment_id TEXT, -- Instagram comment ID (if from comment)
  comment_text TEXT, -- Full comment text
  
  -- Contact information
  phone TEXT, -- Extracted phone number (from bio or message)
  email TEXT, -- Email (if provided)
  
  -- Lead status
  status TEXT DEFAULT 'new', -- new, contacted, qualified, converted, lost
  status_notes TEXT, -- Notes on status changes
  
  -- Attribution (for ROAS calculation)
  campaign_id TEXT, -- Meta Ads campaign ID (if from paid ad)
  ad_id TEXT, -- Specific ad ID (if from paid ad)
  attribution_type TEXT, -- view, click, engagement
  
  -- Conversion tracking
  converted_to_order BOOLEAN DEFAULT false,
  converted_order_id UUID REFERENCES orders(id), -- Link to order if converted
  converted_at TIMESTAMPTZ, -- When lead converted to order
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb, -- Additional flexible data
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_leads_tenant_id ON leads(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leads_source ON leads(source);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_instagram_user_id ON leads(instagram_user_id);
CREATE INDEX IF NOT EXISTS idx_leads_reel_id ON leads(reel_id);
CREATE INDEX IF NOT EXISTS idx_leads_campaign_id ON leads(campaign_id) WHERE campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_leads_converted ON leads(converted_to_order) WHERE converted_to_order = true;
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);

-- Row Level Security (RLS)
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Tenant isolation
-- Users can only access leads for their tenant
CREATE POLICY leads_isolation ON leads
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

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_leads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update updated_at
CREATE TRIGGER leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_leads_updated_at();

-- Function: Mark lead as converted when order is created
-- This can be called from order creation workflow
CREATE OR REPLACE FUNCTION mark_lead_converted(
  p_lead_id UUID,
  p_order_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE leads
  SET 
    converted_to_order = true,
    converted_order_id = p_order_id,
    converted_at = NOW(),
    status = 'converted',
    updated_at = NOW()
  WHERE id = p_lead_id;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE leads IS 'Tracks leads from Instagram and other sources. Enables attribution: Campaign → Lead → Order → Revenue.';
COMMENT ON COLUMN leads.source IS 'Source of lead: instagram, facebook, organic, referral';
COMMENT ON COLUMN leads.status IS 'Lead status: new, contacted, qualified, converted, lost';
COMMENT ON COLUMN leads.campaign_id IS 'Meta Ads campaign ID for ROAS attribution';
COMMENT ON COLUMN leads.converted_to_order IS 'Whether this lead converted to an order';

