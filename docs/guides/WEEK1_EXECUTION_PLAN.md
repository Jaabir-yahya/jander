# Week 1 Execution Plan: WhatsApp + ERPNext for Nairobi SMEs
## Evidence-Based from India/Nigeria/Brazil | Eastleigh Low-Literacy Customers + Growth SME Owners | Solo Developer Flywheel

**Codename**: Commerce Nairobi MVP  
**Status**: ✅ WhatsApp API + n8n ready | Next: Parse → ERPNext bridge  
**Goal**: Validate 3 core hacks that worked in India/Nigeria → 5 growth SMEs + 10 Eastleigh micro-customers  
**Duration**: 5 days | Cost: KSh 0 (free tier) | Support overhead: Near-zero (human-in-loop design)

---

## Doc Structure (Matches 5 Golden Docs)

This Week 1 plan plugs into your existing doc system:

- **BUILD_PLAN.md** – **Master blueprint: Stage-gated 5-stage lifecycle** (Foundation → Containment → Integration → Maturity → Predictive)  
- **ARCHITECTURE.md** – Overall system (WhatsApp → n8n → ERPNext → M-Pesa → riders)  
- **WORKFLOWS.md** – 7-stage lifecycle (catalog → order → payment → dispatch → repeat)  
- **WEEK1_EXECUTION_PLAN.md** – **This file: Detailed Day 1-5 tasks for Stage 1 (Foundation)**  
- **LIFECYCLE_STAGES.md** – Detailed stage definitions and research citations  
- **CONTEXT.md** – Research: India/Nigeria/Brazil/Egypt/Kenya lessons and citations  
- **TEMPLATE_REGISTRY.md** – Stage 1 template governance system  
- **COMMUNICATION_RAILS.md** – API contracts and data flows

**Reference**: This file aligns with **Stage 1: Foundation** in [`BUILD_PLAN.md`](./BUILD_PLAN.md). See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for detailed stage definitions.

Keep this as the single Week 1 plan to avoid duplicate versions.

---

## Why This Plan (Evidence from Other Countries)

### What Failed in India/Nigeria/Brazil (Don't Repeat)

| Country | Failed Approach | Root Cause | Our Hack |
|---------|-----------------|-----------|----------|
| India (UpeoWhatsApp) | ERP UI exposed to traders | Literacy gap + too many fields | Hide ERP entirely; WhatsApp facade only |
| Nigeria (296+ unread WhatsApps) | No order structure/ticketing | Chat = daily noise | Structured template: `items\|qty\|price` |
| Brazil (Suri/Mercately) | Ownership confusion (who owns data?) | Platform lock-in fear | Use ERPNext (open-source); trader owns data |
| Indonesia (Ginee) | Payment reconciliation hell | Cash + wallets + credit; manual hell | STK push + daily ritual reconciliation |
| Kenya (various pilots) | Starting at micro only | Low-literacy users overload support | Start with growth SMEs → then micro layer |

### What Worked (Replicate Here)

| Country | Success | Why | Nairobi Adaptation |
|---------|---------|-----|-------------------|
| India kirana | Negotiated pricing after inquiry | Matches haggling culture | n8n: "discount?" prompt → auto-calc total |
| Nigeria COD WhatsApp | Trust via COD + chat proof | Buyer sees order + receipt | ERPNext invoice PDF in WhatsApp |
| Brazil hybrid | Human + AI parse | AI fails on slang; agent fixes | Cyber-cafe youth checks low-confidence orders |
| Indonesia offline-first | Queue → send when online | Spotty 4G reality | Redis/n8n queue for messages |
| Kenya (M-Pesa) | Payment = trust anchor | Everyone uses M-Pesa | STK + callback = automatic match |

---

## Nairobi Context: Eastleigh Low-Literacy + Growth SME Owners

### Target Segment 1: Growth SME Owners (Decision Makers)

- **Profile**: Boutique/grocery chains, KES 10–50M turnover, 5–20 staff, Nairobi CBD/Westlands
- **Pain**: Multiple ledgers (cash, M-Pesa, credit), eTIMS stress, stock leakage
- **Motivation**: "Save 30% admin time; I'll pay KSh 10K/mo if it works"
- **Tech comfort**: High (WhatsApp, M-Pesa, often Excel/Sheets)
- **Buying cycle**: 2-week pilot → retain/convert

### Target Segment 2: Eastleigh Low-Literacy Customers (Repeat Buyers)

- **Profile**: Eastleigh shops (Somali/Pakistani-led), 2–10 staff, walk-in + WhatsApp reorders
- **Pain**: Poor inventory visibility, informal credit, unreliable delivery
- **Motivation**: "Protect my business; must be simple enough to show staff"
- **Tech comfort**: Low (WhatsApp only; voice preferred)
- **Buying cycle**: Trust-based, needs proof and handholding

---

## The Ultimate Hack: Reverse-Pyramid Model

```text
Week 1: Growth SME (1 real boutique owner)
  ↓ Quick wins → invoice, M-Pesa reconcile, staff tracking
  ↓ Success = case study
  ↓
Week 2: Downmarket to Eastleigh (10 micro-sellers)
  ↓ Simplified: WhatsApp catalog + daily cash ritual
  ↓ Same ERPNext backend (modular)
  ↓
Revenue: High from growth SMEs (KSh 30K/mo × 5 = KSh 150K)
         + Volume from Eastleigh (KSh 3K/mo × 50 = KSh 150K)
         = ~KSh 300K+/mo by Month 3 (solo dev sustainable)
```

---

## Week 1 Day-by-Day Execution

### Day 1: WhatsApp Webhook + Order Parse Engine

**Goal**: Capture orders from WhatsApp → structured data → ERPNext-ready format

**Tasks**:
1. **WhatsApp Business API Setup** (if not done)
   - Verify SMSLeopard webhook is configured
   - Test incoming message reception
   - Document webhook payload structure

2. **Order Parse Engine** (`apps/whatsapp-business/services/order-parser.js`)
   - Text parsing: Extract `item|qty|price|customer` from free-form messages
   - Voice note handling: Google Cloud Speech-to-Text integration
   - Image OCR: Extract order details from screenshots/photos
   - Confidence scoring: Low confidence → flag for human review

3. **Test Cases**:
   - Happy path: "Order: 2m red chiffon, Jane, +254700456789"
   - Voice note: Swahili/Somali transcription
   - Image: Photo of handwritten order
   - Sheng/Slang: "Nataka nyuma chiffon nyekundu senti kumi"

4. **Deployment**: 
   - Test locally with ngrok
   - Verify n8n can trigger on webhook

**Deliverable**: Order parse function that converts WhatsApp message → structured JSON

**Success Metric**: 80%+ parse accuracy on test orders

---

### Day 2: ERPNext Bridge (Parse → ERPNext API)

**Goal**: Auto-create ERPNext Sales Order from parsed WhatsApp order

**Tasks**:
1. **ERPNext Setup** (if not done)
   - Frappe Cloud instance or self-hosted
   - Create API user with permissions
   - Configure M-Pesa integration module

2. **API Bridge** (`apps/whatsapp-business/services/erpnext-bridge.js`)
   - Map parsed order → ERPNext Sales Order JSON
   - Handle product matching (fuzzy match if product not found)
   - Create customer if new (auto-create from phone number)
   - Handle errors: API down, duplicate order, invalid product

3. **Invoice Generation**:
   - Auto-generate invoice after Sales Order creation
   - Attach invoice PDF to WhatsApp response
   - eTIMS-ready format (KRA compliance)

4. **Test Cases**:
   - New customer + new product
   - Existing customer + existing product
   - Product not found → flag for manual review
   - ERPNext API down → queue for retry

**Deliverable**: ERPNext Sales Order created automatically from WhatsApp order

**Success Metric**: 90%+ successful ERPNext order creation (excluding manual review flags)

---

### Day 3: M-Pesa STK Push + Payment Matching

**Goal**: Send STK push for payment → auto-match callback → update ERPNext

**Tasks**:
1. **Daraja STK Push Integration**
   - Configure STK push endpoint
   - Generate payment request link from ERPNext invoice
   - Send STK push via WhatsApp (template message)

2. **Payment Matching Logic**
   - Daraja callback webhook → extract M-Pesa receipt number
   - Match receipt to invoice number (order_id)
   - Update ERPNext: Payment Entry → Sales Invoice status
   - Handle mismatches: Log to DAILY_LOG for manual review

3. **WhatsApp Payment Confirmation**
   - Auto-send confirmation after payment match
   - Include invoice PDF (paid stamp)
   - Trigger dispatch workflow if order ready

4. **Test Cases**:
   - Successful STK push → payment → match
   - Payment timeout → retry STK push
   - Mismatched amount → flag for review
   - Payment without order → alert trader

**Deliverable**: End-to-end payment flow: STK push → payment → ERPNext update → confirmation

**Success Metric**: 95%+ payment match rate (excluding edge cases)

---

### Day 4: Human-in-Loop Review Queue

**Goal**: Low-confidence orders/payments flagged for human review → fix → continue automation

**Tasks**:
1. **Review Queue System** (Google Sheets or Supabase)
   - Table: `REVIEW_QUEUE` (order_id, reason, confidence_score, status)
   - n8n workflow: Flag low-confidence orders
   - WhatsApp alert to cyber-cafe youth (part-time reviewer)

2. **Review Interface** (Simple web form or WhatsApp commands)
   - Reviewer sees: Original message + parsed data + confidence score
   - Reviewer can: Fix parse errors, approve/reject order
   - Approved orders → continue to ERPNext
   - Rejected orders → WhatsApp trader for clarification

3. **Learning Loop**:
   - Track review corrections → improve parse confidence rules
   - Common errors → add to parse patterns

4. **Test Cases**:
   - Low-confidence order → review queue → approved
   - Payment mismatch → review queue → corrected match
   - Review timeout (24hrs) → escalate to trader

**Deliverable**: Human review queue for edge cases without blocking automation

**Success Metric**: <10% of orders require manual review after Day 4

---

### Day 5: Pilot Onboarding + Success Metrics

**Goal**: Onboard 1 growth SME owner → validate 3 core hacks → prepare Week 2 expansion

**Tasks**:
1. **Pilot Trader Onboarding**
   - Identify 1 growth SME (boutique/grocery chain, CBD/Westlands)
   - Onboarding call: Explain system, set expectations, get product catalog
   - Configure: ERPNext company setup, product import, M-Pesa till number
   - Test run: 3–5 real orders from existing customers

2. **Template Registry Setup** (NEW - Stage 1 Gate Requirement)
   - File: `docs/TEMPLATE_REGISTRY.md` (reference for tracking)
   - Pre-approve 5 core templates in SMSLeopard/Meta dashboard:
     - `order_confirmation`: "Order confirmed: {{order_id}}, Total KSh {{total}}, Pay to {{till_number}}"
     - `payment_request`: "Pay KSh {{amount}} for order {{order_id}}. Till: {{till_number}}"
     - `payment_confirmation`: "Payment received! Order {{order_id}} ready for dispatch."
     - `order_status`: "Order {{order_id}} status: {{status}}. [Tracking details]"
     - `support_acknowledgment`: "Thank you for contacting us. We'll respond within {{time}}."
   - Track approval status, version, usage count
   - Target: < 24 hours approval time (Stage 1 gate)

3. **Success Metrics Dashboard** (Google Sheets or simple dashboard)
   - Orders processed (count)
   - Parse accuracy (%)
   - Payment match rate (%)
   - Delivery rate (%)
   - Time saved (hours/day)
   - Template usage (per template)
   - Trader satisfaction (weekly feedback)

4. **3 Core Hacks Validation**:
   - **Hack 1**: WhatsApp → ERPNext (no ERP UI exposure) → ✅ Works?
   - **Hack 2**: Structured template parsing → ✅ Reduces noise?
   - **Hack 3**: STK push + auto-match → ✅ Reconciliation pain gone?

5. **Stage 1 Gate Review** (Before Week 2):
   - Review Stage 1 gates in [`BUILD_PLAN.md`](./BUILD_PLAN.md):
     - [ ] Webhook infrastructure operational
     - [ ] Template registry with 5+ templates approved
     - [ ] Delivery rate 90%+ (if Week 1 messages sent)
     - [ ] Data capture working (all messages routable to database)
     - [ ] Order parsing 80%+ accuracy (current: 83.3%)
     - [ ] Compliance baseline met (template approval workflow)

6. **Week 2 Preparation**:
   - Document onboarding process
   - Create simplified version for Eastleigh micro-sellers
   - Prepare case study template (if Week 1 successful)

**Deliverable**: 1 growth SME live with working automation; metrics baseline established

**Success Metric**: Trader says "This saves me 2+ hours/day" and commits to Week 2

---

## Week 1 Checklist

### Technical Setup
- [ ] WhatsApp Business API (SMSLeopard) webhook configured and tested
- [ ] Order parse engine built (text + voice + image)
- [ ] ERPNext instance ready (Frappe Cloud or self-hosted)
- [ ] ERPNext API bridge functional (Sales Order creation)
- [ ] Daraja STK push integration working
- [ ] Payment matching logic (callback → ERPNext update)
- [ ] Human review queue system (Google Sheets or Supabase)
- [ ] All scripts saved to `apps/whatsapp-business/services/`

### Pilot Trader
- [ ] 1 growth SME owner identified and onboarded
- [ ] ERPNext company configured (products, customers, M-Pesa till)
- [ ] 3–5 test orders processed end-to-end
- [ ] Trader feedback collected (satisfaction + time saved)
- [ ] Success metrics baseline established

### Documentation
- [ ] Onboarding process documented
- [ ] Known issues/edge cases logged
- [ ] Week 2 expansion plan drafted
- [ ] Case study template prepared (if successful)

---

## Success Metrics (Week 1 Targets)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Orders Processed** | 3–5 test orders | Count in ERPNext |
| **Parse Accuracy** | 80%+ | % of orders parsed correctly (no manual fix) |
| **Payment Match Rate** | 95%+ | % of payments matched to orders automatically |
| **Time Saved** | 2+ hours/day | Trader self-reported |
| **Trader Satisfaction** | 8/10+ | Weekly feedback score |
| **System Uptime** | 99%+ | n8n + ERPNext availability |
| **Manual Review Rate** | <10% | % of orders flagged for human review |

---

## Risks & Mitigations

### Risk 1: Parse Engine Fails on Real Orders
**Mitigation**: 
- Start with high-confidence patterns only
- Human review queue for edge cases
- Learning loop: Track corrections → improve patterns

### Risk 2: ERPNext API Down/Unreliable
**Mitigation**:
- Retry logic with exponential backoff
- Queue orders in Google Sheets as backup
- Manual fallback process documented

### Risk 3: Payment Matching Fails (M-Pesa Ref Mismatch)
**Mitigation**:
- Daily reconciliation ritual (6 PM audit)
- Alert trader on mismatches
- Manual match interface in review queue

### Risk 4: Trader Overwhelmed / Doesn't See Value
**Mitigation**:
- Weekly check-in call
- Show metrics dashboard (time saved, orders processed)
- Be ready to pivot based on feedback

### Risk 5: Week 1 Takes Longer Than 5 Days
**Mitigation**:
- Focus on MVP: Just WhatsApp → ERPNext (skip advanced features)
- Defer human review queue if needed (manual check for Week 1)
- Core goal: Prove 3 hacks work, not perfect system

---

## Week 2 Preview (If Week 1 Successful)

### Expansion Plan
- **Week 2 Goal**: Downmarket to 10 Eastleigh micro-sellers
- **Simplified Version**: 
  - WhatsApp catalog only (no ERPNext UI)
  - Basic order log (Google Sheets)
  - Manual payment matching (daily ritual)
- **Revenue Target**: First paid signups (KSh 3K–10K/mo per trader)

### Core Hacks Validation (Week 1 → Week 2)
1. **Hack 1** (WhatsApp → ERPNext): Proven with growth SME → Apply to micro-sellers (simplified)
2. **Hack 2** (Structured parsing): Refined patterns from Week 1 → Scale to 10 traders
3. **Hack 3** (STK push + match): Validated with growth SME → Roll out to Eastleigh (with manual backup)

---

## References to Other Docs

- **For technical details**: See `ARCHITECTURE.md` (ERPNext setup, M-Pesa integration)
- **For workflow details**: See `WORKFLOWS.md` (7-stage lifecycle, order capture flows)
- **For evidence/research**: See `CONTEXT.md` (India/Nigeria/Brazil lessons, failure modes)
- **For overall timeline**: See `BUILD_PLAN.md` (Week 2–12 roadmap)

---

**Last Updated**: Week 1 execution start date  
**Next Review**: End of Week 1 (retrospective + Week 2 prep)
