# Strategic Setup: Learning from Proven Patterns

**Based on successful implementations in India, Brazil, Nigeria, and Kenya**

**Core Philosophy**: Learn from proven patterns → Adapt to local context → Stay disciplined on costs, rollout speed, and operational simplicity.

---

## 🎯 The Proven Pattern (Research-Based)

### Stage 1: Foundation (Weeks 1-2) - **WE ARE HERE**

**What Works (India/Brazil Pattern):**
1. **Start with orchestration layer first** (n8n) - connects everything
2. **Database as single source of truth** (Supabase) - not workflows
3. **Payment reconciliation automated from day 1** - manual matching kills scale
4. **Multi-tenant from start** - even if launching with 1 trader

**What Doesn't Work:**
- ❌ Building custom API wrappers (use native integrations)
- ❌ Storing business data in orchestration layer
- ❌ Manual payment matching
- ❌ Single-tenant architecture (refactoring later is expensive)

---

## 🏗️ Smart Setup Strategy

### Current State Analysis

**✅ What We Have:**
- Supabase database (13+ tables, migrations applied)
- n8n Docker (running, ready for workflows)
- Meta WhatsApp credentials (configured)
- M-Pesa Daraja credentials (sandbox, passkey configured)
- Tenant config (sample tenant created)

**⏳ What We Need:**
- n8n workflows imported and configured
- Webhooks connected (Meta → n8n, M-Pesa → n8n)
- Test end-to-end flow

---

## 📋 Setup Priority (Based on Proven Patterns)

### Priority 1: Core Orchestration (n8n Workflows)

**Why First:** Everything flows through n8n. Without it, nothing works.

**What to Import (In Order):**
1. `00_lookup_tenant_config.json` ⭐ **START HERE**
   - Every workflow needs tenant config
   - Validates tenant exists
   - Loads credentials dynamically

2. `01_classify_message_v2.json`
   - Routes incoming messages
   - Determines: order, inquiry, payment, support

3. `02_check_consent.json`
   - Compliance check
   - Required before sending messages

4. `03_send_whatsapp_v2.json`
   - Sends WhatsApp messages
   - Uses tenant config for credentials

5. `06_reconcile_payment_v2.json`
   - **Critical**: Payment matching
   - This is where startups die without automation

**Why This Order:**
- India pattern: Start with routing → then actions
- Brazil pattern: Consent first → then messaging
- Nigeria pattern: Payment reconciliation is non-negotiable

---

### Priority 2: Webhook Configuration

**Meta WhatsApp Webhook:**
- URL: `https://your-domain.com/webhook/whatsapp?tenant_id=sme_001`
- Events: `messages`, `message_status`
- Verify Token: From `.env`

**M-Pesa Callback:**
- URL: `https://your-domain.com/webhook/mpesa-callback?tenant_id=sme_001`
- For sandbox: Use ngrok for local testing

**Why Webhooks Second:**
- Without webhooks, workflows can't receive data
- But workflows must exist first (chicken/egg)

---

### Priority 3: Test End-to-End

**Test Flow (Proven Pattern):**
1. Send WhatsApp message → n8n receives
2. Classify message → route to order parser
3. Create order in Supabase
4. Send STK Push → customer pays
5. M-Pesa callback → auto-match payment
6. Update order status → send confirmation

**Success Criteria:**
- 95%+ payment matching accuracy
- <5% parse failures
- <2s response time

---

## 🧠 Learning from Other Markets

### India Pattern (WhatsApp Commerce Leaders)

**What They Did Right:**
- Started with orchestration layer (Zapier/n8n)
- Database as single source of truth (Postgres)
- Payment reconciliation automated from day 1
- Multi-tenant from start

**What We're Adopting:**
- ✅ n8n as orchestration layer
- ✅ Supabase as database
- ✅ Automated payment matching
- ✅ Multi-tenant architecture

---

### Brazil Pattern (Payment Integration)

**What They Did Right:**
- Native payment integrations (no wrappers)
- Multi-rail payments (multiple providers)
- Tax compliance automated
- Human-in-the-loop for edge cases

**What We're Adopting:**
- ✅ Native M-Pesa Daraja integration
- ✅ Multi-rail support (M-Pesa, PesaLink, Airtel Money)
- ✅ eTIMS/KRA integration ready
- ✅ Review queue for low-confidence cases

---

### Nigeria Pattern (Scale & Reliability)

**What They Did Right:**
- Phone number as primary identity
- Consent tracking from day 1
- Fallback strategies (WhatsApp → SMS)
- Offline-first design

**What We're Adopting:**
- ✅ Phone number as primary key
- ✅ Consent table in database
- ✅ SMS fallback ready
- ✅ Offline queue handling

---

## 🎯 Setup Checklist (Smart Order)

### Phase 1: Core Infrastructure (Today)

- [x] Supabase database setup
- [x] n8n Docker running
- [x] Credentials configured
- [ ] **Import n8n workflows (Priority 1-5)**
- [ ] **Configure webhooks**

### Phase 2: Integration (Tomorrow)

- [ ] Test WhatsApp webhook reception
- [ ] Test M-Pesa callback
- [ ] Test payment matching
- [ ] Test end-to-end flow

### Phase 3: Validation (Day 3)

- [ ] Validate non-negotiables (6 checks)
- [ ] Test with real data
- [ ] Monitor for 24 hours
- [ ] Fix any issues

---

## 💡 Key Insights from Research

### 1. Start Simple, Scale Smart

**Don't:**
- Build custom API wrappers
- Over-engineer early
- Skip payment reconciliation

**Do:**
- Use native integrations
- Start with proven patterns
- Automate payment matching from day 1

### 2. Database First, Workflows Second

**Why:**
- Workflows are transient
- Database is truth
- If workflows break, data persists

**Pattern:**
- All business data → Supabase
- Workflows → orchestrate, don't store

### 3. Multi-Tenant from Day 1

**Why:**
- Single-tenant → expensive refactor later
- Multi-tenant → scales naturally
- Even if launching with 1 trader

**Pattern:**
- `tenant_config` table
- `tenant_id` in all tables
- RLS for isolation

---

## 🚀 Next Steps

1. **Import n8n workflows** (Priority 1-5)
2. **Configure webhooks** (Meta + M-Pesa)
3. **Test end-to-end** (validate flow)
4. **Monitor & iterate** (fix issues)

**Time Estimate:** 2-3 hours for complete setup

---

## 📚 References

- **Core Docs:**
  - `PROJECT_MASTER.md` - Complete context
  - `ARCHITECTURE_PRINCIPLES.md` - Non-negotiables
  - `BUILD_PLAN.md` - Execution plan
  - `WORKFLOWS.md` - Business processes
  - `WhatsApp_Commerce_Technical_KB.md` - Technical specs

- **Research Sources:**
  - India: WhatsApp Commerce leaders (Meesho, JioMart patterns)
  - Brazil: Payment integration patterns (PagSeguro, Mercado Pago)
  - Nigeria: Scale patterns (Flutterwave, Paystack)
  - Kenya: Local adaptations (Safaricom, M-Pesa patterns)

---

**Last Updated:** January 9, 2026  
**Status:** Ready for n8n workflow import
