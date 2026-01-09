-- Migration 005: Fix tenant_config Relationship
-- 
-- This migration fixes the tenant_config.tenant_id (TEXT) → tenants.id (UUID) relationship
-- by adding a proper UUID foreign key column and updating RLS policies.
--
-- Status: Production hardening - Required for multi-tenant security
-- Date: January 9, 2026
--
-- Reference: docs/VERIFICATION_REPORT.md - Issue #1

-- ============================================
-- STEP 1: Add tenant_uuid FK Column
-- ============================================

-- Add tenant_uuid column with FK constraint
ALTER TABLE tenant_config 
ADD COLUMN tenant_uuid UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Create index for RLS performance (critical for policy evaluation)
CREATE INDEX idx_tenant_config_tenant_uuid ON tenant_config(tenant_uuid);

-- ============================================
-- STEP 2: Migrate Existing Data
-- ============================================

-- Migrate data: Match tenant_config.tenant_id (TEXT) to tenants.phone or tenants.name
-- This is safe because tenant_id was originally meant to be an identifier
UPDATE tenant_config tc
SET tenant_uuid = t.id
FROM tenants t
WHERE (tc.tenant_id = t.phone OR tc.tenant_id = t.name)
  AND tc.tenant_uuid IS NULL;

-- ============================================
-- STEP 3: Verify Migration
-- ============================================

-- Verify no NULLs after migration (should return 0)
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count
    FROM tenant_config
    WHERE tenant_uuid IS NULL;
    
    IF null_count > 0 THEN
        RAISE EXCEPTION 'Migration failed: % rows have NULL tenant_uuid', null_count;
    ELSE
        RAISE NOTICE '✅ Migration successful: All tenant_config rows have tenant_uuid';
    END IF;
END $$;

-- ============================================
-- STEP 4: Update RLS Policy
-- ============================================

-- Drop old policy (if exists)
DROP POLICY IF EXISTS "tenant_config_isolation" ON tenant_config;

-- Create new policy using tenant_uuid (UUID) instead of tenant_id (TEXT)
CREATE POLICY "Users can only access tenant_config from their tenant"
ON tenant_config FOR ALL
TO authenticated
USING (tenant_uuid = public.current_tenant_id())
WITH CHECK (tenant_uuid = public.current_tenant_id());

-- ============================================
-- STEP 5: Add NOT NULL Constraint (After Verification)
-- ============================================

-- Make tenant_uuid required (after data migration verified)
ALTER TABLE tenant_config 
ALTER COLUMN tenant_uuid SET NOT NULL;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Verify FK constraint exists
DO $$
DECLARE
    fk_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
          ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'tenant_config'
          AND tc.constraint_type = 'FOREIGN KEY'
          AND kcu.column_name = 'tenant_uuid'
    ) INTO fk_exists;
    
    IF NOT fk_exists THEN
        RAISE EXCEPTION '❌ Migration failed: FK constraint not found';
    ELSE
        RAISE NOTICE '✅ Migration successful: FK constraint verified';
    END IF;
END $$;

