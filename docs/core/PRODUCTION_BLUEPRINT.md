# **NAIROBI SUPER SUITE: COMPLETE PRODUCTION BLUEPRINT**

**The Business Process Drama - Operational Runbook**  
**Date:** January 9, 2026 | Status: Production-Ready

---

## **THE FINAL CONTEXT SUMMARY**

You are building the **definitive revenue automation engine for Nairobi SMEs**: Instagram Reels → WhatsApp Orders → M-Pesa Payments → Revenue Analytics. Priced at KSh 1,499/month. Your architecture uses **n8n as the central orchestrator**, **Supabase as the state manager**, with official APIs from Meta and Safaricom. This is not a technical system but a **business process drama** that must survive Nairobi's chaotic reality.

---

## **THE COMPLETE ORCHESTRATION DRAMA**

### **1. THE CAST (Your APIs as Actors)**

| **Actor** | **Role** | **Temperament** | **Understudy** |
|-----------|----------|-----------------|----------------|
| **Instagram API** | Celebrity Lead | High-maintenance, script changes | Comment scraping |
| **WhatsApp Cloud API** | The Messenger | Reliable but strict | SMS (Africa's Talking) |
| **M-Pesa Daraja** | The Banker | Precise, hates improv | Manual confirmation |
| **Supabase** | Stage Manager | Calm, organized | None - critical |
| **SME Owner** | Audience/Patron | Demanding, impatient | Must always be pleased |

### **2. THE THREE-ACT STRUCTURE**

**ACT I: COURTSHIP (Lead Capture)**
- *Scene 1:* Reel creates desire → "YES" comment
- *Scene 2:* Instagram DM invitation
- *Scene 3:* WhatsApp catalog delivery
- **Tension:** Will lead convert before losing interest?

**ACT II: TRANSACTION (Payment & Trust)**
- *Scene 1:* Order parsing → STK Push
- *Scene 2:* Payment confirmation drama
- *Scene 3:* ETA promise → Delivery anxiety
- **Climax:** Payment matches ±15 KSh!

**ACT III: AFTERMATH (Retention & Insight)**
- *Scene 1:* Delivery confirmation → Review request
- *Scene 2:* ROAS truth revelation
- *Scene 3:* Inventory alerts → Restock decisions
- **Resolution:** Business grows or learns painful lesson

### **3. THE BACKSTAGE ORCHESTRATION**

```
MAIN STAGE (n8n Workflows):
├── ACT I: Lead Funnel
│   ├── Scene: Comment Monitor (webhook)
│   ├── Scene: DM Handler (retry logic)
│   └── Scene: Catalog Presenter (WA template)
│
├── ACT II: Transaction  
│   ├── Scene: Order Interpreter (NLP for Sheng)
│   ├── Scene: STK Pusher (fallback ready)
│   └── Scene: Payment Reconciler (fuzzy match ±KSh 15)
│
└── ACT III: Retention
    ├── Scene: Delivery Tracker (ETA updates)
    ├── Scene: Review Solicitor
    └── Scene: Insight Generator (ROAS calculator)

BACKSTAGE (Essential Support):
├── Understudy System: SMS fallback for every scene
├── Prompt Corner: Human intervention queue
├── Stage Notes: Complete audit logging
├── Emergency Curtain: "Pause automation" button
└── Box Office: Automated billing & collections
```

### **4. THE CRITICAL MISSING SCENES (Operational Runbook)**

**Scene A: The Onboarding Drama**
```yaml
Workflow: ONBOARDING_NewTenant
Trigger: M-Pesa payment received
Steps:
1. Extract phone → Send onboarding link via WhatsApp
2. Collect: Business name, Instagram, category
3. Create Supabase tenant + RLS policies
4. Configure n8n workflows with tenant_id
5. Test Instagram→WhatsApp connection
6. Send "Go Live" confirmation
Success: <15 minutes to first automated lead
```

**Scene B: The Support Triage**
```
Problem → Escalation Path → Resolution
──────────────────────────────────────
Payment mismatch → WhatsApp owner → Manual match
Instagram banned → SMS customers → Emergency number
WA rate limit → Switch to SMS → Retry later
Customer angry → Human agent tag → Personal call
```

**Scene C: The Nairobi Exceptions**
1. **"Ni bei gani?"** → Price inquiry workflow
2. **"Nataka ile blue"** → Image recognition fallback
3. **Forgot payment reference** → Manual reconciliation UI
4. **"Natumia pesa ya mama"** → Customer identity linking
5. **Cash-in-hand sales** → Manual entry interface

### **5. THE PRODUCTION TIMELINE**

**WEEK 1-2: AUDITIONS & CASTING**
- Secure Meta tokens, Daraja credentials
- Build core 3 scenes: Comment → DM → Catalog
- Test with your own Instagram → WhatsApp

**WEEK 3-4: REHEARSALS WITH UNDERSTUDIES**
- Add SMS fallback for every WhatsApp scene
- Build error improvisation branches
- Load test with simulated traffic

**WEEK 5-6: PREVIEW PERFORMANCES**
- 3 pilot SMEs (free)
- You as hidden prompter fixing errors
- Refine based on audience feedback

**WEEK 7+: THE RUNNING SHOW**
- Automation runs the drama
- You become house manager (monitoring)
- Monthly scene revisions based on analytics

---

## **THE IMMEDIATE BUILD PLAN**

### **PHASE 1: FOUNDATIONS (Next 72 Hours)**

**Step 1: Build the Emergency Infrastructure**

**Database Migration:** `apps/supabase/migrations/011_create_support_infrastructure.sql`

```sql
-- Support Cases Table
CREATE TABLE IF NOT EXISTS support_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  case_type TEXT CHECK (case_type IN ('payment_issue', 'api_down', 'customer_complaint', 'technical_issue')),
  priority TEXT CHECK (priority IN ('critical', 'high', 'medium', 'low')) DEFAULT 'medium',
  status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'escalated')) DEFAULT 'open',
  automated BOOLEAN DEFAULT FALSE,
  assigned_to TEXT, -- WhatsApp number or 'system'
  description TEXT,
  resolution_notes TEXT,
  resolution_time INTERVAL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Manual Entries Table (for cash sales, manual reconciliations)
CREATE TABLE IF NOT EXISTS manual_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  entry_date DATE DEFAULT CURRENT_DATE,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  entry_type TEXT CHECK (entry_type IN ('sale', 'expense', 'payment', 'adjustment')),
  reference TEXT, -- M-Pesa receipt, invoice number, etc
  reconciled BOOLEAN DEFAULT FALSE,
  reconciled_with_order_id UUID REFERENCES orders(id),
  entered_by TEXT, -- Staff WhatsApp for audit
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tenant Automation Control (Emergency Pause)
CREATE TABLE IF NOT EXISTS tenant_automation_control (
  tenant_id UUID PRIMARY KEY REFERENCES tenants(id),
  automation_paused BOOLEAN DEFAULT FALSE,
  pause_reason TEXT,
  paused_at TIMESTAMPTZ,
  paused_by TEXT, -- Who paused it
  fallback_mode TEXT CHECK (fallback_mode IN ('sms', 'manual', 'none')) DEFAULT 'sms',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Health Check Logs
CREATE TABLE IF NOT EXISTS health_check_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id), -- NULL for system-wide checks
  check_type TEXT, -- 'instagram_api', 'whatsapp_api', 'mpesa_api', 'database', 'workflow'
  status TEXT CHECK (status IN ('healthy', 'degraded', 'down')) DEFAULT 'healthy',
  response_time_ms INT,
  error_message TEXT,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_support_cases_tenant_status ON support_cases(tenant_id, status);
CREATE INDEX idx_support_cases_priority ON support_cases(priority, created_at DESC);
CREATE INDEX idx_manual_entries_tenant_date ON manual_entries(tenant_id, entry_date DESC);
CREATE INDEX idx_manual_entries_reconciled ON manual_entries(reconciled, tenant_id);
CREATE INDEX idx_health_check_type_time ON health_check_logs(check_type, checked_at DESC);

-- RLS Policies
ALTER TABLE support_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_automation_control ENABLE ROW LEVEL SECURITY;

CREATE POLICY support_cases_isolation ON support_cases
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));

CREATE POLICY manual_entries_isolation ON manual_entries
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));

CREATE POLICY automation_control_isolation ON tenant_automation_control
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));
```

**Step 2: Create the Three Emergency Workflows**

#### **Workflow 1: EMERGENCY_ModeActivate**

**File:** `apps/n8n/workflows/18_emergency_mode_activate.json`

**Purpose:** Pause automation for affected tenant, switch to fallback mode

**Trigger:** Manual (via webhook or n8n UI)

**Steps:**
1. Check if tenant exists
2. Update `tenant_automation_control` → `automation_paused = true`
3. Set `fallback_mode` (sms/manual)
4. Notify customers via SMS: "Temporarily taking orders via SMS"
5. Create support case: `case_type = 'api_down'`
6. Log incident for post-mortem
7. Send WhatsApp alert to owner: "Automation paused. Reason: [reason]"

**Success:** Tenant in safe mode, customers notified, support case created

#### **Workflow 2: REVENUE_CollectionEnforcer**

**File:** `apps/n8n/workflows/19_revenue_collection_enforcer.json`

**Purpose:** Automated payment reminders and collection

**Trigger:** Cron (Daily 8 PM)

**Steps:**
1. Query unpaid orders >24 hours old
2. For each order:
   - Check reminder count
   - If 0 reminders: Send polite WhatsApp reminder
   - If 1 reminder: Send urgent reminder
   - If 2 reminders: Send final notice
   - If 3 reminders: Suspend account, offer payment plan
3. Update order: `reminder_count++`, `last_reminder_at = NOW()`
4. Tag customers: `payment_reminder_sent = true`
5. Log in `support_cases` if escalated

**Success:** Payment reminders sent, at-risk customers identified

#### **Workflow 3: SUPPORT_EscalationRouter**

**File:** `apps/n8n/workflows/20_support_escalation_router.json`

**Purpose:** Route low-confidence automation to human agents

**Trigger:** Any workflow with confidence <80%

**Steps:**
1. Receive workflow context (order_id, payment_id, etc)
2. Check confidence score
3. If <80%:
   - Create support case: `automation = false`, `priority = 'high'`
   - Notify agent via WhatsApp with context
   - Provide full context: "Customer wants return", order details
4. Log resolution time for SLA tracking
5. Learn from resolution to improve automation

**Success:** Human agent notified, case tracked, resolution logged

**Step 3: Health Monitoring System**

#### **Workflow 4: HEALTH_DailyCheck**

**File:** `apps/n8n/workflows/21_health_daily_check.json`

**Purpose:** Daily health check of all critical systems

**Trigger:** Cron (7 AM daily)

**Steps:**
1. Check Instagram token validity (API call)
2. Check WhatsApp Business API status (API call)
3. Check M-Pesa Daraja connectivity (OAuth test)
4. Check tenant workflow execution rates (query Supabase)
5. Check database connection pool (query test)
6. For each check:
   - Log to `health_check_logs`
   - If fail: Create support case, send WhatsApp alert to YOU
   - Activate fallback if critical

**Success:** All systems healthy, or alerts sent for failures

---

### **PHASE 2: CORE REVENUE ENGINE (Week 1)**

**Priority Scene: Payment Reconciliation Drama**
- **Why**: Without payment matching, nothing else matters
- **Success Metric**: 98.5% auto-match rate (±KSh 15)
- **Error Handling**: 4-layer fallback (exact → fuzzy → human → queue)

**Build Order:**
1. **MP_Reconciler workflow** (M-Pesa webhook → order matching) ⭐ **START HERE**
2. **WA_Order_Parser** (WhatsApp message → order creation)
3. **MP_STK_Trigger** (Order → STK Push)
4. **IG_Lead_Capture** (Instagram comment → lead)

---

### **PHASE 3: TRUST & SCALE (Week 2)**

1. **Delivery ETA System**: Reduces "where's my order?" by 80%
2. **Inventory Intelligence**: Prevents overselling, builds reliability  
3. **Circuit Breaker**: Prevents cascade API failures

---

### **PHASE 4: INTELLIGENCE & STICKINESS (Week 3-4)**

1. **ROAS Analytics**: Shows "which Reels make money"
2. **KRA Compliance**: Auto-invoices, eTIMS ready
3. **Customer Insights**: Segmentation, retention predictions

---

## **THE DIRECTOR'S DECISION POINT**

**Choose your opening scene (build this first):**

**OPTION 1: PAYMENT RECONCILIATION DRAMA** *(Recommended)*
- Most critical path
- Proves core value instantly
- Builds trust immediately
- **If this fails, nothing else matters**

**OPTION 2: "YES" COMMENT TO DM ROMANCE**
- Visual, impressive demo
- Shows automation magic
- But without payment matching, it's just lead generation

**OPTION 3: "WHERE'S MY ORDER?" SUSPENSE**
- Builds customer trust
- Reduces support burden
- But requires payment system first

---

## **THE COMPLIANCE CHECKLIST**

**Before First Paying Customer:**
- [ ] Data Protection Act (Kenya) compliance documented
- [ ] KRA eTIMS invoice formatting validated
- [ ] Meta WhatsApp template messages approved
- [ ] Safaricom Daraja production credentials secured
- [ ] Tenant data isolation (RLS) penetration tested
- [ ] Right-to-be-forgotten procedure documented

---

## **THE SUCCESS METRICS**

**Technical Metrics:**
- Payment auto-match rate: 98.5%+
- Workflow success rate: 99.5%+
- Lead-to-order time: <5 minutes
- API latency P95: <2 seconds

**Business Metrics:**
- Customer acquisition: 5-10 SMEs Week 1
- MRR: KSh 15K Week 1 → KSh 50K Week 4
- Churn: <10% monthly
- Support tickets: <1 per tenant per week

---

## **THE ULTIMATE INSIGHT**

You are not building software. You are **directing a business process drama** where:

- **Stage** = n8n workflow canvas
- **Script** = Nairobi SME business logic  
- **Actors** = APIs with personalities
- **Audience** = Nairobi SMEs
- **Critics** = your analytics
- **Applause** = monthly recurring revenue

---

## **IMMEDIATE NEXT ACTION**

1. **Build MP_Reconciler workflow TODAY** ⭐
2. **Create support_cases and manual_entries tables** ⭐
3. **Test with ONE Nairobi SME tomorrow**
4. **Ask them**: "What would make you stop using this?"

Your technical foundation is excellent. Now build the **operational protocols** (seatbelts, airbags, emergency brakes) before hitting Nairobi's chaotic roads.

**The curtain rises in 72 hours. Which scene will you perfect first?**

---

## **BUILD PRIORITY**

1. ✅ Payment Reconciliation (MP_Reconciler) - **START HERE**
2. ✅ Emergency Workflows (3 critical ones)
3. ✅ Support Infrastructure (tables + protocols)
4. → Core Revenue Engine (Week 1)
5. → Trust & Scale (Week 2)
6. → Intelligence (Week 3-4)

**Your first line of code should be the `support_cases` table. Your first n8n workflow should be `MP_Reconciler`. Your first test should be with a real Nairobi SME asking "What would make you quit?"**

Now go direct your drama. The audience is waiting.

---

**End of PRODUCTION BLUEPRINT** ✅

