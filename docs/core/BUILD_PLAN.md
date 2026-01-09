# Build Plan & Execution Guide: 5-Stage Lifecycle Master Blueprint

**Stage-gated lifecycle blueprint following proven patterns from India/Brazil/Nigeria/SEA. This document is the single source of truth for all implementation decisions.**

> **Reference**: See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for detailed stage definitions and research citations.

---

## Overview: The 5-Stage Lifecycle Pattern

Based on research across leading markets (India, Brazil, Kenya, Latin America, Southeast Asia), successful WhatsApp Business API implementations evolve through 5 distinct, repeatable lifecycle stages. Your Nairobi-specific implementation follows this pattern.

**Master Rule**: Cannot proceed to Stage N+1 until all Stage N gates are passed.

---

## Stage 1: Foundation (Weeks 1-2)

**Research Pattern**: Webhook verification → Template governance → Data capture to database  
**Nairobi Implementation**: WhatsApp webhook → n8n → Google Sheets → Order parser → Template registry  
**Maturity Marker**: All messages routable to database; templates pre-approved; compliance baseline met

### Stage Gates (Must Pass to Proceed to Stage 2)

**⚠️ CRITICAL: Do not start Stage 2 until all Stage 1 gates are passed.**

- [ ] **Webhook Infrastructure**: SMSLeopard → n8n webhook receiving messages reliably (tested with 10+ messages)
- [ ] **Template Registry**: 5+ pre-approved WhatsApp templates operational and tracked
- [ ] **Delivery Rate**: 90%+ message delivery rate achieved (research benchmark)
- [ ] **Data Capture**: All messages routable to database (Google Sheets ORDERS sheet)
- [ ] **Order Parsing**: 80%+ parse accuracy on test orders (current: 83.3%)
- [ ] **Compliance Baseline**: Template approval workflow established

### Week 1: Core Infrastructure

**Day 1: WhatsApp Webhook + Order Parse Engine** ✅ COMPLETE

- ✅ Order Parse Engine built (`apps/whatsapp-business/services/order-parser.js`)
- ✅ Tested: 10/12 tests passing (83.3% success rate)
- ✅ Text parsing: English, Swahili, Sheng formats
- ✅ Voice/Image parsing: Google Cloud integration ready (optional)
- ✅ Confidence scoring: Flags low-confidence orders for review
- ⏳ Webhook receiver configured (SMSLeopard → n8n)
- ⏳ Test incoming message reception
- ⏳ Document webhook payload structure (see [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md))

**Day 2: ERPNext Bridge (Parse → ERPNext API)**

**Goal**: Auto-create ERPNext Sales Order from parsed WhatsApp order

**Tasks**:
1. ERPNext Setup (if not done)
   - Frappe Cloud instance or self-hosted
   - Create API user with permissions
   - Configure M-Pesa integration module

2. API Bridge (`apps/whatsapp-business/services/erpnext-bridge.js`)
   - Map parsed order → ERPNext Sales Order JSON
   - Handle product matching (fuzzy match if product not found)
   - Create customer if new (auto-create from phone number)
   - Handle errors: API down, duplicate order, invalid product

3. Invoice Generation
   - Auto-generate invoice after Sales Order creation
   - Attach invoice PDF to WhatsApp response
   - eTIMS-ready format (KRA compliance)

4. Test Cases
   - New customer + new product
   - Existing customer + existing product
   - Product not found → flag for manual review
   - ERPNext API down → queue for retry

**Deliverable**: ERPNext Sales Order created automatically from WhatsApp order  
**Success Metric**: 90%+ successful ERPNext order creation (excluding manual review flags)

**Day 3: M-Pesa STK Push + Payment Matching**

**Goal**: Send STK push for payment → auto-match callback → update ERPNext

**Tasks**:
1. Daraja STK Push Integration
   - Configure STK push endpoint
   - Generate payment request link from ERPNext invoice
   - Send STK push via WhatsApp (template message)

2. Payment Matching Logic
   - Daraja callback webhook → extract M-Pesa receipt number
   - Match receipt to invoice number (order_id)
   - Update ERPNext: Payment Entry → Sales Invoice status
   - Handle mismatches: Log to DAILY_LOG for manual review

3. WhatsApp Payment Confirmation
   - Auto-send confirmation after payment match
   - Include invoice PDF (paid stamp)
   - Trigger dispatch workflow if order ready

4. Test Cases
   - Successful STK push → payment → match
   - Payment timeout → retry STK push
   - Mismatched amount → flag for review
   - Payment without order → alert trader

**Deliverable**: End-to-end payment flow: STK push → payment → ERPNext update → confirmation  
**Success Metric**: 95%+ payment match rate (excluding edge cases)

**Day 4: Human-in-Loop Review Queue**

**Goal**: Low-confidence orders/payments flagged for human review → fix → continue automation

**Tasks**:
1. Review Queue System (Google Sheets or Supabase)
   - Table: `REVIEW_QUEUE` (order_id, reason, confidence_score, status)
   - n8n workflow: Flag low-confidence orders
   - WhatsApp alert to cyber-cafe youth (part-time reviewer)

2. Review Interface (Simple web form or WhatsApp commands)
   - Reviewer sees: Original message + parsed data + confidence score
   - Reviewer can: Fix parse errors, approve/reject order
   - Approved orders → continue to ERPNext
   - Rejected orders → WhatsApp trader for clarification

3. Learning Loop
   - Track review corrections → improve parse confidence rules
   - Common errors → add to parse patterns

4. Test Cases
   - Low-confidence order → review queue → approved
   - Payment mismatch → review queue → corrected match
   - Review timeout (24hrs) → escalate to trader

**Deliverable**: Human review queue for edge cases without blocking automation  
**Success Metric**: <10% of orders require manual review after Day 4

**Day 5: Pilot Onboarding + Template Registry**

**Goal**: Onboard 1 growth SME owner → validate 3 core hacks → establish template governance

**Tasks**:
1. Pilot Trader Onboarding
   - Identify 1 growth SME (boutique/grocery chain, CBD/Westlands)
   - Onboarding call: Explain system, set expectations, get product catalog
   - Configure: ERPNext company setup, product import, M-Pesa till number
   - Test run: 3–5 real orders from existing customers

2. **Template Registry Setup** (NEW - Stage 1 Requirement)
   - File: `docs/TEMPLATE_REGISTRY.md`
   - Pre-approve 5 core templates:
     - `order_confirmation`: "Order confirmed: {{order_id}}, Total KSh {{total}}, Pay to {{till_number}}"
     - `payment_request`: "Pay KSh {{amount}} for order {{order_id}}. Till: {{till_number}}"
     - `payment_confirmation`: "Payment received! Order {{order_id}} ready for dispatch."
     - `order_status`: "Order {{order_id}} status: {{status}}. [Tracking details]"
     - `support_acknowledgment`: "Thank you for contacting us. We'll respond within {{time}}."
   - Track approval status, version, usage count

3. Success Metrics Dashboard (Google Sheets or simple dashboard)
   - Orders processed (count)
   - Parse accuracy (%)
   - Payment match rate (%)
   - Delivery rate (%)
   - Time saved (hours/day)
   - Trader satisfaction (weekly feedback)

4. 3 Core Hacks Validation
   - **Hack 1**: WhatsApp → ERPNext (no ERP UI exposure) → ✅ Works?
   - **Hack 2**: Structured template parsing → ✅ Reduces noise?
   - **Hack 3**: STK push + auto-match → ✅ Reconciliation pain gone?

**Deliverable**: 1 growth SME live with working automation; template registry operational; metrics baseline established  
**Success Metric**: Trader says "This saves me 2+ hours/day" and commits to Week 2

### Week 2: Foundation Completion

**Template Governance**
- Template approval workflow established
- Version control system (track template versions)
- Usage tracking per template (how many times each template used)
- Template performance tracking (delivery rate, engagement)

**Delivery Monitoring**
- Log all WhatsApp API responses (message_id, status, delivery_timestamp)
- Track delivery status webhooks from SMSLeopard
- Dashboard: Delivery rate (target 90%+)
- Alert on low delivery rate (<90%)

**Basic Bot Responses**
- Simple keyword-based responses for common queries
- "Order status" → Query database → Send status via template
- "Payment" → Check pending orders → Send STK push link
- "Help" → Route to review queue → Send acknowledgment

**Metrics Dashboard**
- Orders processed (count)
- Parse accuracy (%)
- Payment match rate (%)
- Delivery rate (%)
- Time saved (hours/day)
- Template usage (per template)

### Stage 1 Success Criteria

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| **Delivery Rate** | 90%+ | WhatsApp API delivery status | ⏳ |
| **Parse Accuracy** | 80%+ | % orders parsed correctly | ✅ 83.3% |
| **Payment Match Rate** | 95%+ | % payments auto-matched | ⏳ |
| **Template Approval Time** | < 24hrs | Time from submission to approval | ⏳ |
| **System Uptime** | 99%+ | n8n + ERPNext availability | ⏳ |

**Stage 1 Complete When**: All stage gates passed ✅ + 1 growth SME successfully onboarded with 3–5 real orders processed end-to-end.

**Current Status**: Day 1 complete (Order Parse Engine tested). Days 2–5 in progress.

---

## Stage 2: Containment (Weeks 3-4)

**Research Pattern**: Intent detection → Bot routing (60-80% containment) → Human handoff with context  
**Nairobi Implementation**: Intent classification → Automated responses → Review queue escalation  
**Maturity Marker**: 60-80% of queries resolved by bot; agent handoffs preserve conversation context

### Stage Gates (Must Pass to Proceed to Stage 3)

**⚠️ CRITICAL: Do not start Stage 3 until all Stage 2 gates are passed.**

- [ ] **Intent Detection**: System classifies messages into intents (order, payment, support, catalog)
- [ ] **Containment Rate**: 60-80% of queries resolved by bot (research benchmark)
- [ ] **Time-to-Agent**: < 5 minutes for escalated cases
- [ ] **Re-contact Rate**: < 20% (customers don't need to ask twice)
- [ ] **3 Critical Workflows**: Order tracking, payment links, ticket triage operational

### Week 3: Intent Detection + Bot Routing

**Intent Detection System**

**File**: `apps/whatsapp-business/services/intent-detector.js`

**Intent Classification** (Keyword-based initially, ML-enhanced in Stage 5):
- **Order Tracking**: "where", "track", "status", "order", "niko wapi" (Swahili)
- **Payment**: "pay", "payment", "mpesa", "paid", "maliza" (Swahili)
- **Support**: "help", "issue", "problem", "complaint", "msaada" (Swahili)
- **Catalog**: "catalog", "products", "items", "list", "bidhaa" (Swahili)

**Confidence Scoring**:
- High confidence (≥0.8): Auto-route to appropriate workflow
- Medium confidence (0.5-0.79): Suggest intent, ask for confirmation
- Low confidence (<0.5): Route to review queue

**Workflow 1: Order Tracking**

**Intent**: "Where is my order?" / "Order status"

**Flow**:
```
Customer: "Where is my order O001?"
    ↓
Intent Detection: order_tracking (confidence: 0.9)
    ↓
Query Database: SELECT * FROM orders WHERE order_id = 'O001'
    ↓
Format Response: "Your order O001 is [status]. [Tracking details]"
    ↓
Send via WhatsApp template: order_status
```

**Workflow 2: Payment Links**

**Intent**: "I want to pay" / "Payment" / Pending order detected

**Flow**:
```
Customer: "I want to pay"
    ↓
Intent Detection: payment (confidence: 0.9)
    ↓
Query Database: SELECT * FROM orders WHERE customer_phone = '+254...' AND payment_status = 'Pending'
    ↓
Generate STK Push: POST to Daraja API
    ↓
Send WhatsApp: payment_request template with STK push link
```

**Workflow 3: Ticket Triage**

**Intent**: Support request

**Flow**:
```
Customer: "I have a problem with my order"
    ↓
Intent Detection: support (confidence: 0.8)
    ↓
Classify Urgency: high/medium/low (based on keywords)
    ↓
Route to Review Queue: CREATE row in REVIEW_QUEUE
    ↓
Store Conversation Summary: [Original message, intent, context]
    ↓
Notify Trader: WhatsApp alert with context summary
    ↓
Send Acknowledgment: support_acknowledgment template to customer
```

### Week 4: Containment Optimization

**Bot Response Enhancement**

**Context Awareness**:
- Remember previous messages in session (store in Redis or session table)
- Multi-turn conversations (follow-up questions handled)
- Escalation triggers (low confidence, high urgency → human handoff)

**Example**:
```
Customer: "Where is my order?"
Bot: "Your order O001 is ready for dispatch."
Customer: "When will it arrive?"
Bot: "Expected delivery: Tomorrow 2-4 PM. Your rider will call before delivery."
Customer: "Can I change the address?"
Bot: "Let me connect you with our support team..." [Escalates with context]
```

**Containment Metrics**

**Tracking**:
- Bot resolved vs. escalated (count per intent)
- Time-to-agent for escalated cases (average, median)
- Re-contact rate (same customer, same issue within 48hrs)

**Dashboard**:
- Containment rate by intent type
- Time-to-agent distribution
- Re-contact rate trend
- Bot accuracy per intent

**Human Handoff with Context**

**Context Summary Storage**:
```
{
  "session_id": "session_123",
  "customer_phone": "+254700456789",
  "intent": "support",
  "confidence": 0.6,
  "conversation_history": [
    {"role": "customer", "message": "Where is my order?"},
    {"role": "bot", "message": "Your order O001 is ready..."},
    {"role": "customer", "message": "Can I change address?"}
  ],
  "escalation_reason": "Low confidence + address change requires manual approval",
  "timestamp": "2026-01-09T14:30:00Z"
}
```

**Handoff Process**:
1. Store conversation summary in database
2. Notify reviewer/trader with full context
3. Reviewer sees conversation history + parsed data
4. Reviewer can continue conversation seamlessly

### Stage 2 Success Criteria

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| **Containment Rate** | 60-80% | % queries resolved by bot | ⏳ |
| **Time-to-Agent** | < 5 min | Time from escalation to human response | ⏳ |
| **Re-contact Rate** | < 20% | % customers asking same question twice | ⏳ |
| **Intent Accuracy** | 85%+ | % intents classified correctly | ⏳ |

**Stage 2 Complete When**: All stage gates passed ✅ + 60%+ containment rate achieved with 3 critical workflows operational.

---

## Stage 3: Integration Depth (Weeks 5-8)

**Research Pattern**: OMS ↔ n8n ↔ WhatsApp, Payment gateway sync, CRM integration  
**Nairobi Implementation**: Supabase migration, ERPNext bridge, M-Pesa webhooks, Post-purchase sequences  
**Maturity Marker**: Full order-to-delivery cycle automated; payment reconciliation idempotent; no manual data entry

### Stage Gates (Must Pass to Proceed to Stage 4)

**⚠️ CRITICAL: Do not start Stage 4 until all Stage 3 gates are passed.**

- [ ] **Full Lifecycle Automation**: All 7 stages automated (catalog → order → payment → dispatch → delivery → accounting → repeat)
- [ ] **Payment Reconciliation**: 95%+ automated (idempotent, no manual matching)
- [ ] **Post-Purchase Sequences**: Multi-message sequences working
- [ ] **No Manual Data Entry**: All order data flows automatically
- [ ] **CRM Features**: Customer tier tracking, order history operational

### Week 5: Supabase Migration + Full Sync

**Database Migration**

**Migration Strategy**:
1. Set up Supabase instance (Postgres database)
2. Create tables matching Google Sheets schema
3. Use Whalesync for gradual transition (dual-write for 1 week)
4. Test with real data before full cutover
5. Update n8n workflows to use Supabase nodes

**Schema Mapping**:
- Google Sheets `ORDERS` → Supabase `orders` table
- Google Sheets `PAYMENTS` → Supabase `payments` table
- Google Sheets `REVIEW_QUEUE` → Supabase `review_queue` table
- Google Sheets `TRADERS` → Supabase `traders` table
- Google Sheets `PRODUCTS` → Supabase `products` table

**Real-time Triggers**

**Supabase Realtime Subscriptions**:
- Subscribe to `orders` table for new rows
- Subscribe to `payments` table for payment updates
- Auto-trigger n8n workflows on database changes
- Eliminate polling delays (instant updates)

### Week 6: Post-Purchase Sequences

**Sequence 1: Order Confirmation → Payment → Dispatch → Delivery → Review**

**Trigger**: Order created in database

**Message Flow**:
1. **Order Confirmation** (Immediate)
   - Template: `order_confirmation`
   - Content: Order ID, product details, total amount, payment instructions

2. **Payment Request** (If not paid in 1 hour)
   - Template: `payment_request`
   - Content: STK push link, order ID, amount, deadline

3. **Payment Confirmation** (When payment matched)
   - Template: `payment_confirmation`
   - Content: Order ID, payment receipt, dispatch timeline

4. **Dispatch Notification** (When order marked "Ready")
   - Template: `dispatch_notification`
   - Content: Order ID, rider details, tracking info, estimated delivery

5. **Delivery Confirmation** (When order marked "Delivered")
   - Template: `delivery_confirmation`
   - Content: Order ID, delivery confirmation, review request link

6. **Review Request** (24 hours after delivery)
   - Template: `review_request`
   - Content: Order ID, review link, incentive (if applicable)

**Sequence 2: Cart Recovery**

**Trigger**: Order created, payment not received within 24hrs

**Message Flow**:
1. **Reminder 1** (24hrs after order)
   - Template: `payment_reminder_1`
   - Content: Order ID, STK push link, "Complete your order"

2. **Reminder 2** (48hrs after order)
   - Template: `payment_reminder_2`
   - Content: Order ID, urgency message, STK push link

3. **Final Reminder** (72hrs after order)
   - Template: `payment_reminder_final`
   - Content: Order ID, "Last chance" message, STK push link
   - **Escalate**: If still not paid, notify trader for manual follow-up

**Research Validation**: 30-36% cart recovery rate achievable (India/Brazil benchmarks)

### Week 7: Payment Retry Logic

**STK Push Retry System**

**Flow**:
```
Order Created → Generate STK Push (Attempt 1)
    ↓
Wait 5 minutes
    ↓
Check Payment Status
    ↓
If Not Paid → Retry STK Push (Attempt 2)
    ↓
Wait 10 minutes
    ↓
Check Payment Status
    ↓
If Not Paid → Final Retry (Attempt 3)
    ↓
Wait 15 minutes
    ↓
If Still Not Paid → Escalate to Trader
```

**Idempotent Design**:
- Use unique `checkout_request_id` per STK push attempt
- Track attempts in database
- Don't create duplicate payment entries
- Match by phone + amount (±50 KSh tolerance)

**Research Validation**: Reduces manual follow-up by 70% (India payment automation case)

### Week 8: Returns & CRM Features

**Returns Initiation Workflow**

**Flow**:
```
Customer: "I want to return order O001"
    ↓
Intent Detection: return_request (confidence: 0.9)
    ↓
Query Database: Get order details
    ↓
Create Return Ticket: INSERT into returns table
    ↓
Notify Trader: WhatsApp alert with return request + order details
    ↓
Trader Approval: Approve/reject via WhatsApp or web interface
    ↓
If Approved:
  - Update order status: "Return Initiated"
  - Process refund: Update payment status
  - Send confirmation: return_confirmed template
    ↓
If Rejected:
  - Send explanation: return_rejected template
  - Offer alternative: Exchange or credit note
```

**CRM Features**

**Customer Tier Tracking**:
- **New**: First order (1 order)
- **Regular**: 2-10 orders
- **VIP**: 11+ orders OR high order value

**Order History Lookup**:
- Query all orders by customer phone
- Show purchase pattern (frequency, average order value)
- Enable quick reorders

**Purchase Pattern Analysis**:
- Identify top products per customer
- Detect purchase frequency (weekly, monthly, seasonal)
- Flag inactive customers for retention campaigns (Stage 5)

**Segment-Based Routing**:
- VIP customers → Higher priority responses
- New customers → More handholding (lower bot containment)
- Regular customers → Standard automated flows

### Stage 3 Success Criteria

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| **Cycle Time Reduction** | 50%+ | Time from order to delivery | ⏳ |
| **Payment Automation** | 95%+ | % payments auto-matched | ⏳ |
| **Cart Recovery Rate** | 30-36% | % abandoned orders recovered | ⏳ |
| **Manual Data Entry** | 0% | All data flows automatically | ⏳ |

**Stage 3 Complete When**: All stage gates passed ✅ + full order-to-delivery cycle automated with 95%+ payment automation.

---

## Stage 4: Operational Maturity (Weeks 9-12)

**Research Pattern**: Template A/B testing, analytics instrumentation, segment-based routing, ROI tracking  
**Nairobi Implementation**: Template backlog management, analytics dashboard, optimization framework  
**Maturity Marker**: Data-driven template iterations; ROI quantified (18:1+ ratio); cost per contact benchmarked

### Stage Gates (Must Pass to Proceed to Stage 5)

**⚠️ CRITICAL: Do not start Stage 5 until all Stage 4 gates are passed.**

- [ ] **Template Backlog**: 10-15 templates per workflow domain (Orders: 5, Payments: 3, Support: 5, Returns: 2)
- [ ] **Analytics Dashboard**: Message → Action → Outcome tracking operational
- [ ] **A/B Testing Framework**: Template performance comparison working
- [ ] **ROI Quantified**: Financial ROI calculated (target 18:1+ ratio)
- [ ] **Segment-Based Routing**: Customer tier, intent confidence, sentiment flags

### Week 9: Template Backlog Management

**Template Domains & Counts**

**Orders Domain** (5 templates):
1. `order_confirmation` - Order created confirmation
2. `order_reminder` - Payment reminder for pending orders
3. `order_payment_link` - STK push link for payment
4. `order_dispatch` - Dispatch notification with tracking
5. `order_delivery` - Delivery confirmation and review request

**Payments Domain** (3 templates):
1. `payment_request` - Initial STK push request
2. `payment_confirmation` - Payment matched confirmation
3. `payment_failure` - Payment timeout or failure notification

**Support Domain** (5 templates):
1. `support_acknowledgment` - Initial support request acknowledgment
2. `support_escalation` - Escalation to trader notification
3. `support_resolution` - Issue resolved confirmation
4. `support_followup` - Follow-up to check satisfaction
5. `support_satisfaction` - Satisfaction survey request

**Returns Domain** (2 templates):
1. `return_initiated` - Return request acknowledgment
2. `return_refund` - Refund processed confirmation

**Total**: 15 templates minimum (meets research benchmark)

**Template Versioning**

**Version Control System**:
- Track versions per template (v1, v2, v3...)
- Store template content, approval status, usage count
- A/B test variations (test v1 vs v2 performance)

**Performance Tracking**:
- Delivery rate per template
- Engagement rate (clicks/opens per template)
- Conversion rate (message → action per template)
- Template cost (if using per-message pricing)

**File**: `docs/TEMPLATE_REGISTRY.md` (detailed template tracking)

### Week 10: Analytics Instrumentation

**Analytics Schema**

**Message → Action → Outcome Tracking**:

```
Message Sent
  ↓ (delivery status)
Message Delivered
  ↓ (engagement)
Link Clicked / Button Tapped
  ↓ (action)
Order Created / Payment Made
  ↓ (outcome)
Revenue Generated / Customer Retained
```

**Database Schema** (Supabase `analytics` table):
```sql
CREATE TABLE analytics (
  event_id TEXT PRIMARY KEY,
  event_type TEXT, -- 'message_sent', 'message_delivered', 'link_clicked', 'order_created', etc.
  template_name TEXT,
  workflow_name TEXT,
  customer_phone TEXT,
  order_id TEXT,
  revenue_kes DECIMAL,
  timestamp TIMESTAMPTZ,
  metadata JSONB -- Additional context
);
```

**KPIs Dashboard**

**Primary KPIs** (Track weekly):
- **Delivery Rate**: Target 90%+ (Stage 1 gate)
- **Engagement Rate**: Clicks/opens per message (target: optimize)
- **Conversion Rate**: Message → Order (target: optimize)
- **Cost per Contact**: Total cost / messages sent (target: minimize)
- **Re-contact Rate**: Same customer, same issue (target: <20%)
- **CSAT**: Customer Satisfaction (target: improve)
- **Cycle Time Reduction**: Time saved vs manual (target: 50%+)

**File**: `docs/ANALYTICS_SCHEMA.md` (detailed metrics definitions)

### Week 11: Optimization Backlog

**Send Time Optimization**

**Kenya-Specific Send Time Discovery**:
- Research example: Serri case (India) found 8-9 PM = 2.3X engagement
- Test different times for Kenya:
  - Morning (8-10 AM): Business hours start
  - Afternoon (1-3 PM): Lunch break
  - Evening (6-9 PM): After work (most likely optimal)
  - Late evening (9-11 PM): Before bed
- Measure engagement rate per time slot
- Optimize workflow timing based on local patterns

**Workflow Optimization**

**Payment Flow Optimization**:
- Current: Order → STK push → Wait → Retry → Escalate
- Optimize: Reduce steps, improve messaging, auto-retry logic
- Goal: Increase payment completion rate

**Intent Prompt Optimization**:
- Improve intent detection prompts
- Add Swahili/Sheng variations
- Reduce false positives

**Agent-Assist Summary Optimization**:
- Refine conversation summaries for reviewers
- Highlight key information (order ID, urgency, customer tier)
- Reduce reviewer time to resolve

**Session Reopen Reduction**:
- Improve bot responses to prevent follow-up questions
- Add proactive information (tracking, delivery time)
- Goal: Reduce re-contact rate

### Week 12: ROI Quantification

**ROI Calculation**

**Formula**: ROI = (Revenue + Time Savings Value - Costs) / Costs

**Revenue Attribution**:
- Orders via WhatsApp (count × average order value)
- Compare to baseline (before WhatsApp automation)
- Measure incremental revenue

**Time Savings Value**:
- Hours saved per trader per day (self-reported)
- Convert to KSh value (trader hourly rate × hours saved)
- Multiply by number of traders

**Costs**:
- WhatsApp API costs (SMSLeopard subscription)
- n8n costs (if paid tier)
- Supabase costs (if paid tier)
- ERPNext costs (if paid tier)
- M-Pesa transaction fees

**Target**: 18:1+ ROI ratio (research benchmark from India/Brazil)

**Market Expansion**

**Second Market Expansion**:
- Expand to Toi, River Road via champions
- Apply Stage 1-4 learnings
- Scale template library to new market
- Refine workflows based on analytics

**Champion Recruitment**:
- Recruit 2 market champions (Gikomba + Eastleigh)
- Champions recruit peers (network effect)
- Provide incentives (free tier extension, commission)

### Stage 4 Success Criteria

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| **Template Count** | 10-15 per domain | Total 40-60 templates | ⏳ |
| **ROI Ratio** | 18:1+ | Revenue/Cost | ⏳ |
| **Engagement Rate** | Track & optimize | Clicks/opens per message | ⏳ |
| **CSAT Movement** | Positive trend | Customer satisfaction scores | ⏳ |

**Stage 4 Complete When**: All stage gates passed ✅ + ROI quantified (18:1+ target) + data-driven optimizations implemented.

---

## Stage 5: Proactive & Predictive (Weeks 13+)

**Research Pattern**: Proactive notifications, retention campaigns, AI-assisted routing, revenue workflows  
**Nairobi Implementation**: Post-MVP advanced features  
**Maturity Marker**: Revenue attributed to WhatsApp; automated workflows scale without manual intervention

### Future Workflows (Post-MVP)

**Proactive Notifications**

**Delivery Delay Alerts**:
- Monitor dispatch → delivery time
- If delivery time exceeds estimate → Send delay alert
- Include updated ETA and apology

**Return Window Reminders**:
- Calculate return window (typically 7 days)
- Send reminder at day 5: "You have 2 days left to return order O001"
- Include return instructions

**Loyalty Offer Notifications**:
- Track customer purchase history
- Identify VIP customers (11+ orders)
- Send exclusive offers on birthdays, anniversaries

**Retention Campaigns**

**Reorder Nudges**:
- Predict reorder timing based on purchase history
- Send reminder: "Time to restock? Reorder your usual items"
- Include quick reorder button

**Churn Prediction**:
- Identify inactive customers (no order in 30+ days)
- Send win-back sequence:
  1. Check-in message
  2. Exclusive offer
  3. Feedback request

**Cross-Sell Recommendations**:
- Analyze purchase patterns
- Suggest complementary products
- "Customers who bought X also bought Y"

**AI-Assisted Routing**

**Embeddings-Based Intent Classification**:
- Replace keyword-based with ML model
- Use embeddings for intent classification
- Improve accuracy for Swahili/Sheng/Somali

**Context Summarization**:
- AI-generated conversation summaries
- Highlight key information for agents
- Reduce reviewer time

**Priority Routing**:
- Route based on sentiment (positive/negative/neutral)
- Route based on urgency (high/medium/low)
- Route VIP customers to priority queue

**Revenue Workflows**

**Purchase → Recommendations**:
- After order delivery → Suggest related products
- Timing: 24-48 hours after delivery (when customer is happy)

**Return Initiated → Refund Tracking → Re-engagement**:
- Process refund automatically
- Track refund status
- Send re-engagement offer after refund processed

**Predictive Delivery Issue Alerts**:
- Monitor delivery patterns
- Predict potential delays
- Proactive communication before customer complains

### Stage 5 Success Criteria

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| **Revenue per Contact** | Track & optimize | Revenue / messages sent | Future |
| **Churn Reduction** | Track & optimize | % inactive customers recovered | Future |
| **AI Intent Accuracy** | 95%+ | ML-based intent classification | Future |

**Stage 5 Complete When**: Proactive workflows operational + retention campaigns live + AI-assisted routing implemented.

---

## Timeline Overview

| Stage | Weeks | Goal | Traders | Orders/Week | Primary Metrics |
|-------|-------|------|---------|-------------|-----------------|
| **Stage 1: Foundation** | 1–2 | Webhook + templates + data capture | 1–5 | 20–50 | Delivery rate (90%+), Parse accuracy (80%+) |
| **Stage 2: Containment** | 3–4 | Intent routing + bot responses | 5–20 | 50–100 | Containment rate (60-80%), Time-to-agent (<5min) |
| **Stage 3: Integration** | 5–8 | Full lifecycle automation | 20–50 | 200–400 | Payment automation (95%+), Cycle time (-50%) |
| **Stage 4: Maturity** | 9–12 | Analytics + optimization | 50–100 | 500+ | ROI (18:1+), Template count (40-60) |
| **Stage 5: Predictive** | 13+ | Proactive + AI routing | 100+ | 500+ | Revenue per contact, Churn reduction |

---

## Key Metrics to Track by Stage

### Stage 1 Metrics (Foundation)
- Delivery rate (target: 90%+)
- Parse accuracy (target: 80%+)
- Payment match rate (target: 95%+)
- Template approval time (target: <24hrs)
- System uptime (target: 99%+)

### Stage 2 Metrics (Containment)
- Containment rate (target: 60-80%)
- Time-to-agent (target: <5 minutes)
- Re-contact rate (target: <20%)
- Intent accuracy (target: 85%+)

### Stage 3 Metrics (Integration)
- Cycle time reduction (target: 50%+)
- Payment automation (target: 95%+)
- Cart recovery rate (target: 30-36%)
- Manual data entry (target: 0%)

### Stage 4 Metrics (Maturity)
- Template count (target: 10-15 per domain)
- ROI ratio (target: 18:1+)
- Engagement rate (track & optimize)
- CSAT movement (positive trend)

### Stage 5 Metrics (Predictive)
- Revenue per contact (track & optimize)
- Churn reduction (track & optimize)
- AI intent accuracy (target: 95%+)

---

## Stage Gate Enforcement Rules

**Rule 1**: Cannot start Stage N+1 until all Stage N gates are passed.

**Rule 2**: Every feature/idea must map to a stage. If it doesn't fit, it's not ready.

**Rule 3**: Stage 1–2 are mandatory. Stage 3–4 are recommended. Stage 5 is optional (future).

**Rule 4**: Weekly review of stage gates. Update checklist as gates are passed.

**Rule 5**: If a stage gate is blocked, pause and resolve before proceeding.

---

## Nairobi-Specific Adaptations by Stage

### Stage 1 Adaptations
- **M-Pesa** (not UPI/PIX) as payment anchor
- **Swahili/Somali** language support in parser
- **Low-literacy** user considerations (voice notes, simple templates)
- **Eastleigh context**: Trust-based, requires proof (invoice PDFs)

### Stage 2 Adaptations
- **Eastleigh context**: More human handoffs (trust-based interactions)
- **Growth SME context**: Higher bot containment expected (tech-comfortable)
- **Cyber-cafe youth** reviewers (not full-time agents, part-time support)

### Stage 3 Adaptations
- **Boda rider coordination** (not 3PL APIs, manual v1)
- **eTIMS compliance** (KRA requirements, invoice format)
- **Cash + M-Pesa** hybrid payments (both payment types supported)

### Stage 4 Adaptations
- **Kenya-specific send time** optimization (may differ from India/Brazil)
- **Local template language** (Swahili/English mix, not pure English)
- **M-Pesa-specific** payment analytics (till vs paybill, transaction patterns)

### Stage 5 Adaptations
- **Nairobi delivery** patterns (traffic, boda networks)
- **Kenya payment** preferences (M-Pesa dominance, cash backup)
- **Local retention** triggers (seasonal patterns, market-specific)

---

## Tool Alignment by Stage

| Tool | Stage 1 | Stage 2 | Stage 3 | Stage 4 | Stage 5 |
|------|---------|---------|---------|---------|---------|
| **WhatsApp API** | Webhooks, Templates | Bot Responses | Sequences | A/B Testing | Proactive |
| **n8n** | Simple Triggers | Intent Routing | Multi-step Funnels | Analytics Hooks | AI Integration |
| **Google Sheets** | Data Capture | Context Storage | Migration Prep | Analytics Log | Archive |
| **Supabase** | - | - | Primary DB | Analytics DB | Predictive Data |
| **ERPNext** | Basic Orders | - | Full OMS | Advanced Features | AI Features |
| **M-Pesa** | Basic Matching | Retry Logic | Full Reconciliation | Analytics | Predictive |

---

## Cost Breakdown by Stage

| Stage | Weeks | Key Costs | Total Budget |
|-------|-------|-----------|--------------|
| **Stage 1** | 1–2 | SMSLeopard (KSh 1,999/mo), Google Sheets (Free), n8n (Free), M-Pesa Daraja (Free sandbox) | KSh 0–5K |
| **Stage 2** | 3–4 | SMSLeopard, n8n (Free), Google Sheets (Free) | KSh 0–5K |
| **Stage 3** | 5–8 | SMSLeopard, Supabase (KSh 3K/mo), n8n (Free), M-Pesa Daraja (Live, ~KSh 5/transaction) | KSh 10–20K |
| **Stage 4** | 9–12 | SMSLeopard, Supabase, ERPNext (KSh 2K–5K/mo), M-Pesa (Live) | KSh 20–30K |
| **Stage 5** | 13+ | All above + AI/ML services (optional) | KSh 30K+ |

**Total 12-Week Budget**: ~KSh 50K–60K (all stages)  
**Revenue Target by Month 3**: KSh 300K+/mo (covers costs)

---

## Migration Paths Between Stages

### Stage 1 → Stage 2: Adding Intent Detection
- Keep existing webhook infrastructure
- Add intent detection layer before order parser
- Maintain review queue for low-confidence intents
- **No breaking changes** to existing flows

### Stage 2 → Stage 3: Database Migration
- Gradual migration: Google Sheets → Supabase
- Dual-write for 1 week (verify data consistency)
- Update n8n workflows to use Supabase nodes
- **Breaking change**: Database endpoint changes

### Stage 3 → Stage 4: Analytics Layer
- Add analytics instrumentation (non-breaking)
- Create analytics tables in Supabase
- Track all workflows without disrupting existing flows
- **No breaking changes** to existing flows

### Stage 4 → Stage 5: AI Integration
- Add AI layer for intent classification (optional upgrade)
- Keep keyword-based as fallback
- A/B test AI vs keyword-based
- **No breaking changes** to existing flows

---

## References to Other Docs

- **For detailed stage definitions**: See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md)
- **For communication rails**: See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md)
- **For technical architecture**: See [`ARCHITECTURE.md`](./core/ARCHITECTURE.md)
- **For workflow details**: See [`WORKFLOWS.md`](./core/WORKFLOWS.md)
- **For research context**: See [`CONTEXT.md`](./CONTEXT.md)
- **For Week 1 details**: See [`WEEK1_EXECUTION_PLAN.md`](./WEEK1_EXECUTION_PLAN.md)
- **For template registry**: See [`TEMPLATE_REGISTRY.md`](./TEMPLATE_REGISTRY.md)
- **For analytics schema**: See [`ANALYTICS_SCHEMA.md`](./ANALYTICS_SCHEMA.md)

---

**Last Updated**: 2026-01-09  
**Status**: Stage 1 in progress (Day 1 complete, Days 2-5 remaining)  
**Next Review**: End of Week 1 (Stage 1 gate review)
