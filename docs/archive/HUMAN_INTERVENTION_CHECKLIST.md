# Human Intervention Checklist

**What needs human action before we can continue building.**

Based on [`BUILD_PROGRESS.md`](./BUILD_PROGRESS.md) - ~30% of build is blocked by credentials and manual steps.

---

## 🔑 Priority 1: API Credentials (Required for Workflows 3-4, 7)

### 1. SMSLeopard WhatsApp Business API

**What's Needed:**
- [ ] SMSLeopard account created
- [ ] API token obtained
- [ ] Phone Number ID obtained
- [ ] Webhook verification token generated
- [ ] Webhook URL configured in SMSLeopard dashboard

**Where to Get:**
- Sign up: https://smsleopard.co.ke/whatsapp-business.html
- Dashboard: https://smsleopard.co.ke/dashboard

**Time Estimate:** 30-60 minutes (account creation + verification)

**Blocks:**
- Workflow 3: `send_whatsapp`
- Workflow 7: `send_payment_confirmation`

---

### 2. SMS Provider (SMSLeopard or AfricasTalking)

**What's Needed:**
- [ ] SMS provider account created
- [ ] API key obtained
- [ ] Sender ID registered/approved

**Where to Get:**
- SMSLeopard: https://smsleopard.co.ke (same account as WhatsApp)
- AfricasTalking: https://africastalking.com

**Time Estimate:** 15-30 minutes

**Blocks:**
- Workflow 4: `send_sms_fallback`

---

### 3. Supabase Project

**What's Needed:**
- [ ] Supabase account created
- [ ] Project created
- [ ] Project URL obtained
- [ ] Service role key obtained
- [ ] Database migrations run (001 + 002)

**Where to Get:**
- Sign up: https://supabase.com
- Dashboard: https://app.supabase.com

**Time Estimate:** 15 minutes (account) + 10 minutes (migrations)

**Blocks:**
- All database operations
- Workflows 1, 2, 5, 6 (can use mock for testing)

**Action Items:**
1. Create Supabase project
2. Copy project URL and service role key to `.env`
3. Run migrations:
   - Copy `apps/supabase/migrations/001_create_trade_facilitator_schema.sql`
   - Copy `apps/supabase/migrations/002_add_waas_core_tables.sql`
   - Paste into Supabase SQL Editor
   - Execute

---

### 4. M-Pesa Daraja API (Sandbox)

**What's Needed:**
- [ ] Safaricom Developer account created
- [ ] App created
- [ ] Consumer key obtained
- [ ] Consumer secret obtained
- [ ] Shortcode obtained (test shortcode for sandbox)
- [ ] Passkey obtained

**Where to Get:**
- Register: https://developer.safaricom.co.ke
- Dashboard: https://developer.safaricom.co.ke/user/login

**Time Estimate:** 30-60 minutes (account + app creation)

**Blocks:**
- M-Pesa STK Push
- M-Pesa B2C payouts
- Payment reconciliation (workflow 6 can work with mock data)

**Note:** Sandbox credentials are sufficient for testing. Live credentials require business registration.

---

### 5. ERPNext (Optional - Week 5-8)

**What's Needed:**
- [ ] ERPNext instance (Frappe Cloud or self-hosted)
- [ ] API user created
- [ ] API key and secret obtained
- [ ] Base URL obtained

**Where to Get:**
- Frappe Cloud: https://frappecloud.com
- Self-hosted: https://github.com/frappe/frappe

**Time Estimate:** 30-60 minutes (instance setup)

**Blocks:**
- ERPNext Bridge service (can operate in mock mode)
- Week 1 Day 2 tasks (ERPNext integration)

**Note:** Can be deferred until Week 5-8 per BUILD_PLAN.md

---

## 📋 Priority 2: Manual Configuration Steps

### 6. Template Submission

**What's Needed:**
- [ ] Go to SMSLeopard dashboard → WhatsApp → Templates
- [ ] Create 8 templates from `apps/whatsapp-business/templates/trade-facilitator-templates.json`
- [ ] Submit for Meta approval
- [ ] Wait for approval (24-48 hours)
- [ ] Track approval status

**Templates to Submit:**
1. `new_order_to_seller`
2. `payment_link_to_buyer`
3. `payment_confirmation`
4. `delivery_confirmation_request`
5. `order_status_update`
6. `payout_notification`
7. `order_cancelled`
8. `payment_reminder`

**Time Estimate:** 30 minutes (submission) + 24-48 hours (approval)

**Blocks:**
- Template-based messaging (workflow 3)
- Can use session messages (within 24h) without templates

---

### 7. Webhook Configuration

**What's Needed:**
- [ ] n8n running (local or cloud)
- [ ] Webhook URL obtained from n8n
- [ ] Configure webhook in SMSLeopard dashboard
- [ ] Set verify token (match `WEBHOOK_VERIFY_TOKEN` in `.env`)
- [ ] Test webhook reception

**Time Estimate:** 15 minutes

**Blocks:**
- Incoming message reception
- Can test with mock webhooks locally

---

### 8. Environment Variables Setup

**What's Needed:**
- [ ] Copy `.sample.env` to `.env`
- [ ] Fill in all credentials from steps 1-4 above
- [ ] Verify all variables are set

**Time Estimate:** 10 minutes

**Blocks:**
- All services (can use mock mode without credentials)

---

## ✅ What Can Be Built Without Credentials

**Already Built:**
- ✅ All 8 core services
- ✅ Database schema (13 tables)
- ✅ 4 n8n workflows (1, 2, 5, 6)
- ✅ Complete documentation
- ✅ Webhook schemas
- ✅ Test suites

**Can Still Build:**
- ⏳ Workflows 3, 4, 7 (structure ready, need credentials to test)
- ⏳ Additional helper services
- ⏳ More documentation

---

## 🎯 Recommended Order

**Week 1 Day 1 (Today):**
1. ✅ Supabase project + migrations (15 min)
2. ✅ Environment variables setup (10 min)
3. ⏳ SMSLeopard account (30-60 min)
4. ⏳ Template submission (30 min)

**Week 1 Day 2:**
5. ⏳ M-Pesa Daraja sandbox (30-60 min)
6. ⏳ Webhook configuration (15 min)
7. ⏳ Test workflows 1, 2, 5, 6

**Week 1 Day 3:**
8. ⏳ Test workflows 3, 4, 7 (after credentials)
9. ⏳ End-to-end testing

---

## 📝 Quick Start Commands (After Credentials)

```bash
# 1. Configure environment
cd apps/whatsapp-business
cp .sample.env .env
# Edit .env with credentials

# 2. Run database migrations (in Supabase SQL Editor)
# Copy: apps/supabase/migrations/001_create_trade_facilitator_schema.sql
# Copy: apps/supabase/migrations/002_add_waas_core_tables.sql
# Paste and execute in Supabase SQL Editor

# 3. Import n8n workflows
# Open n8n (http://localhost:5678)
# Import: apps/n8n/workflows/01_classify_message.json
# Import: apps/n8n/workflows/02_check_consent.json
# Import: apps/n8n/workflows/05_log_message.json
# Import: apps/n8n/workflows/06_reconcile_payment.json

# 4. Test webhook
curl -X POST http://localhost:5678/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"message": {"id": "test", "from": "+254700456789", "type": "text", "text": {"body": "I want 2m red chiffon"}}}'
```

---

## 🚨 Critical Path

**Must Complete Before Week 1 Day 3:**
1. ✅ Supabase project + migrations
2. ⏳ SMSLeopard account + webhook
3. ⏳ Environment variables

**Can Defer:**
- ERPNext (Week 5-8)
- Template approval (can use session messages)
- M-Pesa live credentials (sandbox sufficient for testing)

---

**Last Updated**: 2026-01-09  
**Status**: Checklist ready, waiting for human intervention  
**Next**: Complete Priority 1 items, then continue building workflows 3-4, 7

