# Week 1 Action Plan - Tomorrow's Complete Guide

**Date:** January 9, 2026  
**Status:** ✅ Locked In - Ready for Deployment  
**Time Estimate:** 4-6 hours

---

## 🎯 Overview

This is your complete step-by-step guide for Week 1 deployment. Follow this in order, check off items as you complete them.

**Goal:** Deploy MVP with 5 traders, 95%+ payment matching, <5% parse failures

---

## Priority 1: Get Credentials (2-3 hours)

### 1.1 Supabase Setup (15 minutes)

**Steps:**
1. Go to https://supabase.com
2. Create new project (name: `jander-nairobi`)
3. Copy Project URL and Service Role Key
4. Open SQL Editor
5. Copy contents of `apps/supabase/migrations/001_create_trade_facilitator_schema.sql`
6. Paste and execute
7. Copy contents of `apps/supabase/migrations/002_add_waas_core_tables.sql`
8. Paste and execute
9. Copy contents of `apps/supabase/migrations/003_add_tenant_config.sql`
10. Paste and execute
11. Verify tables created: `buyers`, `sellers`, `trades`, `tenant_config`, etc.

**Deliverable:** ✅ Supabase project with all 13 tables created

---

### 1.2 SMSLeopard WhatsApp Setup (30-60 minutes)

**Steps:**
1. Go to https://smsleopard.co.ke
2. Sign up for WhatsApp Business API account
3. Complete verification (may take 1-2 days, start now)
4. Get API Token from dashboard
5. Get Phone Number ID from dashboard
6. Configure webhook URL: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
7. Set webhook verify token (generate with: `openssl rand -hex 32`)
8. Test webhook reception (send test message)

**Deliverable:** ✅ SMSLeopard account with webhook configured

---

### 1.3 SMS Provider Setup (15-30 minutes)

**Steps:**
1. Choose provider: SMSLeopard SMS or AfricasTalking
2. Sign up and get API key
3. Register sender ID (e.g., "TRADEFAC")
4. Test SMS sending

**Deliverable:** ✅ SMS provider account with sender ID registered

---

### 1.4 M-Pesa Daraja Setup (30-60 minutes)

**Steps:**
1. Go to https://developer.safaricom.co.ke
2. Create app (get Consumer Key & Consumer Secret)
3. Get Till/Paybill number (or use sandbox)
4. Get Passkey from dashboard
5. Configure callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
6. Test STK Push in sandbox

**Deliverable:** ✅ M-Pesa Daraja credentials configured

---

### 1.5 Environment Variables Setup (10 minutes)

**Steps:**
1. Copy `apps/whatsapp-business/.sample.env` to `apps/whatsapp-business/.env`
2. Fill in all values:
   - Supabase URL, Service Role Key, Anon Key
   - SMSLeopard Token, Phone Number ID
   - SMS Provider API Key, Sender ID
   - M-Pesa Consumer Key, Secret, Shortcode, Passkey
3. Generate verify tokens: `openssl rand -hex 32`
4. Test with: `node scripts/health-check.js`

**Deliverable:** ✅ All environment variables configured

---

## Priority 2: Test & Configure (1-2 hours)

### 2.1 Database Migration Verification (5 minutes)

**Steps:**
1. Open Supabase SQL Editor
2. Run: `SELECT COUNT(*) FROM tenant_config;`
3. Run: `SELECT COUNT(*) FROM trades;`
4. Verify all tables exist (should be 13 tables)

**Deliverable:** ✅ Database verified

---

### 2.2 Import n8n Workflows (15 minutes)

**Steps:**
1. Open n8n (http://localhost:5678 or cloud instance)
2. Import workflows from `apps/n8n/workflows/`:
   - `00_lookup_tenant_config.json`
   - `01_classify_message_v2.json`
   - `03_send_whatsapp_v2.json`
   - `04_send_sms_fallback_v2.json`
   - `06_reconcile_payment_v2.json`
   - `07_send_payment_confirmation_v2.json`
   - `08_submit_to_etims.json`
   - `09_multi_rail_payment.json`
3. Configure environment variables in n8n
4. Activate all workflows

**Deliverable:** ✅ All workflows imported and activated

---

### 2.3 Configure Webhooks (10 minutes)

**Steps:**
1. In SMSLeopard dashboard, set webhook URL: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
2. Set verify token (same as in .env)
3. In M-Pesa Daraja dashboard, set callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
4. Test webhook reception

**Deliverable:** ✅ Webhooks configured and tested

---

### 2.4 Test Workflows (30 minutes)

**Steps:**
1. Run: `node tests/n8n-workflow-tests.js`
2. Run: `node tests/integration-test-suite.js`
3. Run: `node tests/test-multi-tenant.js`
4. Fix any errors
5. Test end-to-end: Send WhatsApp message → Order created → Payment matched

**Deliverable:** ✅ All tests passing

---

### 2.5 Create Sample Tenant Config (10 minutes)

**Steps:**
1. Open Supabase SQL Editor
2. Insert sample tenant:
```sql
INSERT INTO tenant_config (
  tenant_id, tenant_name, waba_phone_number_id, 
  erp_base_url, mpesa_shortcode, payment_rails, tax_system
) VALUES (
  'sme_001', 'Nairobi Boutique', 'YOUR_PHONE_NUMBER_ID',
  'https://erp.example.com', '123456',
  '[{"rail_type": "mpesa", "enabled": true, "priority": 1}]'::jsonb,
  '{"system": "etims", "pin": "A000000000"}'::jsonb
);
```

**Deliverable:** ✅ Sample tenant config created

---

## Priority 3: Deploy (1 hour)

### 3.1 Submit Templates (30 minutes)

**Steps:**
1. Go to SMSLeopard template dashboard
2. Submit 8 core templates:
   - Order Confirmation
   - Payment Due
   - Payment Received
   - Shipment Confirmed
   - Delivery Confirmation
   - Customer Support
   - Feedback Request
   - Monthly Summary
3. Wait for approval (24-48 hours)
4. Use session messages in meantime (within 24h window)

**Deliverable:** ✅ Templates submitted (approval pending)

---

### 3.2 Configure Production Webhooks (10 minutes)

**Steps:**
1. Update webhook URLs to production domain
2. Test webhook reception
3. Verify tenant_id extraction works

**Deliverable:** ✅ Production webhooks configured

---

### 3.3 Test End-to-End Flow (15 minutes)

**Steps:**
1. Send test WhatsApp message: "I want 2m red chiffon"
2. Verify order created in Supabase
3. Verify payment STK push sent
4. Simulate M-Pesa payment
5. Verify payment matched
6. Verify confirmation sent

**Deliverable:** ✅ End-to-end flow working

---

### 3.4 Monitor for 24 Hours (Ongoing)

**Steps:**
1. Check n8n execution logs
2. Monitor Supabase for errors
3. Check payment matching accuracy
4. Review message parse failures
5. Fix any issues

**Deliverable:** ✅ System stable for 24 hours

---

## ✅ Success Criteria

**Week 1 is successful if:**
- [ ] All credentials obtained
- [ ] Database migrations run successfully
- [ ] All workflows imported and tested
- [ ] Webhooks receiving messages
- [ ] Payment matching 95%+ accuracy
- [ ] Message parsing 80%+ accuracy
- [ ] First 5 traders onboarded
- [ ] Zero data isolation breaches

---

## 🚨 Critical Gaps to Address

**1. Personal WhatsApp vs Enterprise WABA**
- **Action:** Offer both paths (Phase 1: Personal WhatsApp, Phase 2: WABA)
- **Timeline:** Week 1-2 (Phase 1), Week 5+ (Phase 2)

**2. eTIMS PIN Requirement**
- **Action:** Two-tier model (formal vs informal)
- **Timeline:** Week 1-8 (formal only), Week 9+ (add informal tier)

**3. Payment Reconciliation Edge Cases**
- **Action:** Manual review queue
- **Timeline:** Week 2-3 (Phase 1)

**4. Message Parsing Accuracy**
- **Action:** Expand regex patterns
- **Timeline:** Week 1-2 (quick win), Week 5+ (voice transcription)

---

## 📋 Checklist

### Credentials
- [ ] Supabase project created
- [ ] SMSLeopard account created
- [ ] SMS provider account created
- [ ] M-Pesa Daraja credentials obtained
- [ ] Environment variables configured

### Database
- [ ] Migration 001 executed
- [ ] Migration 002 executed
- [ ] Migration 003 executed
- [ ] All tables verified
- [ ] Sample tenant config created

### Workflows
- [ ] All v2 workflows imported
- [ ] Environment variables configured in n8n
- [ ] All workflows activated
- [ ] Workflows tested with sample data

### Webhooks
- [ ] SMSLeopard webhook configured
- [ ] M-Pesa callback configured
- [ ] Webhooks tested and receiving

### Testing
- [ ] Workflow tests passing
- [ ] Integration tests passing
- [ ] Multi-tenant tests passing
- [ ] End-to-end flow tested

### Deployment
- [ ] Templates submitted
- [ ] Production webhooks configured
- [ ] First trader onboarded
- [ ] System monitoring active

---

## 🎯 Next Steps After Week 1

**Week 2:**
- Fix payment edge cases
- Improve message parsing accuracy
- Add human review queue UI
- Onboard 5 more traders

**Week 3-4:**
- Intent routing
- Bot responses
- Payment retry logic
- Scale to 25 traders

**See [BUILD_PLAN.md](../core/BUILD_PLAN.md) for complete roadmap.**

---

**Last Updated:** January 9, 2026  
**Status:** ✅ Locked In - Ready for Tomorrow  
**Next:** Follow this guide step-by-step
