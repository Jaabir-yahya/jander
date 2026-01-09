# MVP DEPLOYMENT CHECKLIST

**Date:** _______________  
**Status:** Pre-Deployment  
**Purpose:** Ensure minimal viable deployment is ready

---

## PRE-DEPLOYMENT (Day 1 Morning)

### Infrastructure Setup
- [ ] Create new Supabase test project
- [ ] Create new n8n workspace (or separate folder)
- [ ] Prepare minimal .env file with:
  - [ ] SUPABASE_URL (test project)
  - [ ] SUPABASE_ANON_KEY (test project)
  - [ ] SUPABASE_SERVICE_ROLE_KEY (test project)
  - [ ] N8N_BASE_URL
  - [ ] INSTAGRAM_ACCESS_TOKEN (test account)
  - [ ] M_PESA_CONSUMER_KEY (sandbox)
  - [ ] M_PESA_CONSUMER_SECRET (sandbox)
  - [ ] M_PESA_PASSKEY (sandbox)
  - [ ] WHATSAPP_ACCESS_TOKEN (test account)
  - [ ] PHONE_NUMBER_ID (test account)

### Database Migrations
- [ ] Run migration 001: `tenants` table
- [ ] Run migration 003: `tenant_config` table
- [ ] Run migration 002: `orders` and `payments` tables
- [ ] Verify: `SELECT COUNT(*) FROM tenants;` returns 0
- [ ] Verify: `SELECT COUNT(*) FROM orders;` returns 0
- [ ] Verify: `SELECT COUNT(*) FROM payments;` returns 0

### Workflow Preparation
- [ ] Copy `13_instagram_comment_trigger.json` to MVP folder
- [ ] Copy `10_handle_order_with_confirmation.json` to MVP folder
- [ ] Copy `06_reconcile_payment_v2.json` to MVP folder
- [ ] Rename all other workflows to `.disabled` (keep in repo)
- [ ] Verify 3 workflows are valid JSON

### n8n Setup
- [ ] Login to n8n
- [ ] Create Supabase credentials (test project)
- [ ] Create Instagram credentials (test account)
- [ ] Create M-Pesa credentials (sandbox)
- [ ] Create WhatsApp credentials (test account)
- [ ] Import Workflow 13 (Instagram trigger)
- [ ] Import Workflow 10 (Order handler)
- [ ] Import Workflow 06 (Payment reconciliation)
- [ ] Set all workflows to INACTIVE

### Smoke Tests
- [ ] Manual execute Workflow 13: No errors
- [ ] Manual execute Workflow 10: No errors
- [ ] Manual execute Workflow 06: No errors
- [ ] Check database: All tables empty

---

## CUSTOMER 1 ONBOARDING (Day 1 Afternoon)

### Customer Selection
- [ ] Customer 1 identified: _______________
- [ ] Has Instagram business account: YES / NO
- [ ] Has M-Pesa account: YES / NO
- [ ] Available for 2-hour test: YES / NO

### Manual Setup
- [ ] Insert into `tenants` table:
  ```sql
  INSERT INTO tenants (id, name, phone, status)
  VALUES (gen_random_uuid(), 'Customer 1', '+254...', 'active');
  ```
- [ ] Insert into `tenant_config` table:
  ```sql
  INSERT INTO tenant_config (tenant_id, instagram_handle, m_pesa_phone, ...)
  VALUES ('...', '@customer1', '+254...', ...);
  ```
- [ ] Get tenant_id: _______________
- [ ] Share WhatsApp link with customer

### Customer Briefing
- [ ] Explained: "Testing new tool"
- [ ] Instructions: "Post 'YES' on Instagram"
- [ ] Expected: "You'll get WhatsApp message"
- [ ] Next step: "Reply with order details"
- [ ] Final step: "You'll get payment link"

---

## CUSTOMER 1 TESTING (Day 1 Afternoon)

### Transaction Tracking
- [ ] Instagram comment posted: Time _______________
- [ ] Comment text: _______________
- [ ] WhatsApp message received: YES / NO / LATE
- [ ] WhatsApp message time: _______________
- [ ] Customer replied with order: Time _______________
- [ ] Order text: _______________
- [ ] Order created in database: YES / NO / BROKEN
- [ ] Order ID: _______________
- [ ] Payment link sent: YES / NO (manual if needed)
- [ ] Payment amount: _______________ KSh
- [ ] M-Pesa receipt: _______________
- [ ] Payment reconciled: YES / NO / PARTIAL
- [ ] Total transaction time: _______________ minutes

### Validation Questions
- [ ] Q1: "Did this save you time?" YES / NO / MAYBE
- [ ] Q2: "Would you use this daily?" YES / NO / MAYBE
- [ ] Q3: "Would you pay KSh 1,499/month?" YES / NO / MAYBE
- [ ] Q4: "What would make you stop using this?" _______________

### Issues Logged
- [ ] Issue 1: _______________
- [ ] Issue 2: _______________
- [ ] Issue 3: _______________

### Fixes Applied
- [ ] Fix 1: _______________
- [ ] Fix 2: _______________
- [ ] Fix 3: _______________

---

## CUSTOMER 2 TESTING (Day 2 Morning)

### Customer Selection
- [ ] Customer 2 identified: _______________
- [ ] Different SME type: YES / NO
- [ ] Repeat setup process: DONE

### Transaction Tracking
(Same template as Customer 1)

### Validation Questions
(Same template as Customer 1)

### Pattern Analysis
- [ ] Common issues between Customer 1 & 2: _______________
- [ ] Unique issues: _______________
- [ ] Fixes applied: _______________

---

## VALIDATION DECISION (Day 2 Afternoon)

### Results Summary
- [ ] Customer 1: YES votes: ___ / 3
- [ ] Customer 2: YES votes: ___ / 3
- [ ] Total complete transactions: ___
- [ ] Total failures: ___
- [ ] Total manual interventions: ___

### Decision Made
- [ ] ✅ SUCCESS: Move to Customer 3 + Market-Driven Build
- [ ] ⚠️ PARTIAL: Fix blocking issue + Retest
- [ ] ❌ FAILURE: Pivot (different approach)

### Next Steps
- [ ] Action 1: _______________
- [ ] Action 2: _______________
- [ ] Action 3: _______________

---

## POST-VALIDATION (If SUCCESS)

### Week 1 Priorities
- [ ] Customer Request #1: _______________
- [ ] Customer Request #2: _______________
- [ ] Customer Request #3: _______________

### Week 2 Priorities
- [ ] Fix most common failure: _______________
- [ ] Build highest-impact feature: _______________
- [ ] Onboard Customer 3: _______________

---

**Reference:** `docs/MVP_TESTING_PLAYBOOK.md` for full process

