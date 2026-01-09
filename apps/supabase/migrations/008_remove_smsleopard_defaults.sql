-- Migration: Remove SMSLeopard defaults and update to Meta WhatsApp + Local SMS
-- Date: 2026-01-09
-- Purpose: Remove SMSLeopard provider support, default to Meta WhatsApp and Local SMS

-- Update sms_provider default from 'smsleopard' to 'local'
ALTER TABLE tenant_config 
  ALTER COLUMN sms_provider SET DEFAULT 'local';

-- Update existing rows that use 'smsleopard' to 'local' (or 'africastalking' if they have AfricasTalking config)
UPDATE tenant_config
SET sms_provider = CASE
  WHEN sms_api_key IS NOT NULL AND sms_api_key NOT LIKE 'smsleopard%' THEN 'africastalking'
  ELSE 'local'
END
WHERE sms_provider = 'smsleopard';

-- Update waba_provider default to 'meta' (already set, but ensure it)
ALTER TABLE tenant_config 
  ALTER COLUMN waba_provider SET DEFAULT 'meta';

-- Update existing rows that use 'smsleopard' for WhatsApp to 'meta'
UPDATE tenant_config
SET waba_provider = 'meta'
WHERE waba_provider = 'smsleopard';

-- Note: We keep smsleopard_token column for backward compatibility
-- It can be dropped later if needed, but keeping it allows for easier rollback

-- Add comment to smsleopard_token column indicating it's deprecated
COMMENT ON COLUMN tenant_config.smsleopard_token IS 'DEPRECATED: SMSLeopard provider no longer supported. Use local SMS tool or AfricasTalking.';

-- Add comment to sms_provider column
COMMENT ON COLUMN tenant_config.sms_provider IS 'SMS provider: local (default) or africastalking';

-- Add comment to waba_provider column
COMMENT ON COLUMN tenant_config.waba_provider IS 'WhatsApp Business API provider: meta (default)';

