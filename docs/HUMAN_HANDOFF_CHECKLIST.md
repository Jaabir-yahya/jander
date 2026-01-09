# Human Handoff Checklist

**Date:** January 9, 2026  
**Purpose:** Complete checklist for human intervention before MVP deployment

---

## ✅ Pre-Handoff Verification

Before starting, verify everything is built:

```bash
# 1. Validate all components are in place
node scripts/validate-setup.js

# 2. Check code compiles (if applicable)
cd apps/whatsapp-business && npm install

# 3. Review documentation
# - Read: docs/00_START_HERE.md
# - Read: docs/core/WhatsApp_Commerce_Technical_KB.md
# - Read: docs/guides/WEEK1_ACTION_PLAN.md
```

---

## 📋 Handoff Checklist

### Phase 1: Credentials Setup (2-3 hours)

#### 1.1 Supabase Setup
- [ ] Create Supabase project at https://supabase.com
- [ ] Project name: `jander-nairobi`
- [ ] Copy Project URL → `SUPABASE_URL`
- [ ] Copy Service Role Key → `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Copy Anon Key → `SUPABASE_ANON_KEY`
- [ ] Open SQL Editor
- [ ] Run migration: `apps/supabase/migrations/001_create_trade_facilitator_schema.sql`
- [ ] Run migration: `apps/supabase/migrations/002_add_waas_core_tables.sql`
- [ ] Run migration: `apps/supabase/migrations/003_add_tenant_config.sql`
- [ ] Run migration: `apps/supabase/migrations/004_migrate_to_research_schema.sql`
- [ ] Run migration: `apps/supabase/migrations/005_fix_tenant_config_fk.sql` ⭐ NEW
- [ ] Run migration: `apps/supabase/migrations/006_create_dead_letter_queue.sql` ⭐ NEW
- [ ] Run migration: `apps/supabase/migrations/007_create_error_logs.sql` ⭐ NEW
- [ ] Verify all tables created (including dead_letter_queue, error_logs)
- [ ] Test connection: `node apps/whatsapp-business/scripts/health-check.js`

#### 1.2 SMSLeopard WhatsApp Setup
- [ ] Sign up at https://smsleopard.co.ke
- [ ] Complete business verification
- [ ] Get API Token → `SMSLEOPARD_TOKEN`
- [ ] Get Phone Number ID → `PHONE_NUMBER_ID`
- [ ] Note webhook URL format: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
- [ ] Generate verify token: `openssl rand -hex 32` → `WEBHOOK_VERIFY_TOKEN`
- [ ] **Note:** Webhook configuration happens after n8n is running

#### 1.3 SMS Provider Setup
- [ ] Choose provider: SMSLeopard SMS or AfricasTalking
- [ ] Sign up and get API key
- [ ] Register sender ID (e.g., "TRADEFAC")
- [ ] Set `SMS_PROVIDER` env var
- [ ] Set provider-specific API key

#### 1.4 M-Pesa Daraja Setup
- [ ] Go to https://developer.safaricom.co.ke
- [ ] Create app (get Consumer Key & Secret)
- [ ] Get Till/Paybill number → `MPESA_SHORTCODE`
- [ ] Get Passkey from dashboard → `MPESA_PASSKEY`
- [ ] Note callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
- [ ] Test STK Push in sandbox
- [ ] **For Production:** Submit "Go Live" request

#### 1.5 Environment Variables
- [ ] Copy `.env.example` (root) or `apps/whatsapp-business/.sample.env` to `.env`
- [ ] Fill in all Supabase values
- [ ] Fill in all SMSLeopard values (including `SMSLEOPARD_WEBHOOK_SECRET` ⭐ NEW)
- [ ] Fill in all M-Pesa values (including `MPESA_CONSUMER_SECRET` for signature verification)
- [ ] Fill in all SMS provider values
- [ ] Generate verify tokens: `openssl rand -hex 32`
- [ ] Generate webhook secrets: `openssl rand -hex 32` (for SMSLeopard webhook signature verification)
- [ ] Set `N8N_BASE_URL` (e.g., `http://localhost:5678` or production URL)
- [ ] Set `LOG_LEVEL` (debug, info, warn, error) - default: info
- [ ] Set `ALLOW_UNSIGNED_WEBHOOKS=false` in production (security)
- [ ] Validate environment: `node scripts/validate-env.js` ⭐ NEW
- [ ] Run health check: `node apps/whatsapp-business/scripts/health-check.js`
- [ ] Verify all checks pass

---

### Phase 2: n8n Configuration (1-2 hours)

#### 2.1 n8n Setup
- [ ] Install n8n (local or cloud)
- [ ] Access n8n UI (http://localhost:5678 or cloud URL)
- [ ] Configure credentials in n8n:
  - [ ] Supabase (HTTP Request with API key)
  - [ ] WhatsApp (HTTP Request with Bearer token)
  - [ ] M-Pesa (HTTP Request with Basic Auth)
  - [ ] SMS Provider (HTTP Request with API key)

#### 2.2 Workflow Import
- [ ] Import `apps/n8n/workflows/00_lookup_tenant_config.json`
- [ ] Import `apps/n8n/workflows/01_classify_message_v2.json`
- [ ] Import `apps/n8n/workflows/02_check_consent.json`
- [ ] Import `apps/n8n/workflows/03_send_whatsapp_v2.json`
- [ ] Import `apps/n8n/workflows/04_send_sms_fallback_v2.json`
- [ ] Import `apps/n8n/workflows/05_log_message.json`
- [ ] Import `apps/n8n/workflows/06_reconcile_payment_v2.json`
- [ ] Import `apps/n8n/workflows/07_send_payment_confirmation_v2.json`
- [ ] Import `apps/n8n/workflows/08_submit_to_etims.json`
- [ ] Import `apps/n8n/workflows/09_multi_rail_payment.json`

#### 2.3 Workflow Configuration
- [ ] Configure webhook URLs in each workflow
- [ ] Set environment variables in n8n (or use credentials)
- [ ] Test each workflow with sample data
- [ ] Verify error handling works

#### 2.4 Webhook Configuration
- [ ] Get n8n webhook URLs for:
  - [ ] WhatsApp inbound: `https://your-n8n/webhook/whatsapp?tenant_id=sme_001`
  - [ ] M-Pesa callback: `https://your-n8n/webhook/mpesa-callback?tenant_id=sme_001`
- [ ] Configure SMSLeopard webhook URL
- [ ] Configure SMSLeopard webhook secret in dashboard (must match `SMSLEOPARD_WEBHOOK_SECRET`) ⭐ NEW
- [ ] Configure M-Pesa callback URL
- [ ] Test webhook reception
- [ ] Test webhook signature validation (send test webhook with invalid signature - should reject) ⭐ NEW

---

### Phase 3: Template Submission (30-60 min)

#### 3.1 WhatsApp Templates
- [ ] Review templates in `apps/whatsapp-business/templates/trade-facilitator-templates.json`
- [ ] Submit templates to Meta via SMSLeopard dashboard
- [ ] Wait for approval (24-48 hours)
- [ ] Test approved templates

#### 3.2 Template Testing
- [ ] Send test template message
- [ ] Verify delivery
- [ ] Test template parameters

---

### Phase 4: Database Setup (15 min)

#### 4.1 Tenant Configuration
- [ ] Create first tenant config in Supabase:
  ```sql
  INSERT INTO tenant_config (
    tenant_id,
    waba_phone_number_id,
    waba_access_token,
    erp_base_url,
    erp_company_name,
    mpesa_shortcode,
    mpesa_passkey,
    payment_rails,
    tax_system
  ) VALUES (
    'sme_001',
    'YOUR_PHONE_NUMBER_ID',
    'YOUR_ACCESS_TOKEN',
    'https://erp.example.com',
    'Test Business',
    'YOUR_SHORTCODE',
    'YOUR_PASSKEY',
    '[{"rail_type": "mpesa", "enabled": true, "priority": 1}]',
    '{"system": "etims", "pin": "A000000000", "oscu_endpoint": "..."}'
  );
  ```

---

### Phase 5: Testing (1-2 hours)

#### 5.1 Unit Tests
- [ ] Run: `node scripts/test-all.js`
- [ ] Verify all tests pass
- [ ] Fix any failing tests

#### 5.2 Integration Tests
- [ ] Test WhatsApp webhook reception
- [ ] Test order parsing
- [ ] Test M-Pesa STK Push
- [ ] Test payment reconciliation
- [ ] Test eTIMS submission (if configured)
- [ ] Test SMS fallback

#### 5.3 End-to-End Test
- [ ] Send test order via WhatsApp
- [ ] Verify order created in Supabase
- [ ] Verify WhatsApp confirmation sent
- [ ] Initiate M-Pesa STK Push
- [ ] Complete payment
- [ ] Verify payment matched to order
- [ ] Verify payment confirmation sent

---

### Phase 6: Production Deployment (1 hour)

#### 6.1 Pre-Deployment
- [ ] Review all environment variables
- [ ] Switch to production endpoints (if applicable)
- [ ] Update webhook URLs to production
- [ ] Test all workflows one more time

#### 6.2 Deployment
- [ ] Deploy n8n workflows (activate all)
- [ ] Configure production webhooks
- [ ] Set up monitoring/logging
- [ ] Create backup of configurations

#### 6.3 Post-Deployment
- [ ] Monitor for 24 hours
- [ ] Review error logs
- [ ] Check payment reconciliation accuracy
- [ ] Verify message delivery rates
- [ ] Document any issues

---

## 🚨 Critical Issues to Watch

1. **Webhook Timeouts**
   - Ensure webhooks respond within 5 seconds
   - Implement async processing if needed

2. **Payment Reconciliation**
   - Monitor for unmatched payments
   - Review manual matching queue daily

3. **Template Approval**
   - Templates can take 24-48 hours
   - Plan ahead for new templates

4. **M-Pesa Rate Limits**
   - STK Push: 10 requests/second
   - Implement rate limiting if needed

5. **Supabase RLS**
   - Verify RLS policies are working
   - Test tenant isolation

---

## 📞 Support Resources

- **Technical KB:** `docs/core/WhatsApp_Commerce_Technical_KB.md`
- **Week 1 Guide:** `docs/guides/WEEK1_ACTION_PLAN.md`
- **Quick Reference:** `docs/reference/QUICK_REFERENCE.md`
- **Troubleshooting:** See Technical KB "Troubleshooting & Error Handling" section

---

## ✅ Completion Criteria

MVP is ready when:
- [ ] All credentials configured
- [ ] All workflows imported and tested
- [ ] Webhooks configured and receiving
- [ ] Templates approved (or using session messages)
- [ ] End-to-end test successful
- [ ] Health check passes
- [ ] Monitoring in place

---

**Estimated Total Time:** 4-6 hours  
**Status:** Ready to begin  
**Next:** Start with Phase 1 (Credentials Setup)

---

**Last Updated:** January 9, 2026


