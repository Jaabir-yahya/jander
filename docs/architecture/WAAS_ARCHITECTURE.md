# WhatsApp-as-a-Service (WaaS) Architecture

**Three-layer architecture for Nairobi/Kenya: Channels → Orchestration → System of Record**

This document defines the correct layering for WhatsApp commerce platforms based on successful global implementations (India, Brazil, Nigeria, Kenya). This architecture separates concerns: truth (ERPNext), flow (n8n), and channels (WhatsApp/SMS).

**Reference**: This extends [`TRADE_FACILITATOR_ARCHITECTURE.md`](./architecture/TRADE_FACILITATOR_ARCHITECTURE.md) with proper three-layer separation.

---

## 🧠 The Mental Model: Three Layers

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 3: CHANNELS (Replaceable, Volatile)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ WhatsApp │  │   SMS    │  │   USSD   │  │ Email  │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
│         │            │            │            │        │
└─────────┼────────────┼────────────┼────────────┼────────┘
          │            │            │            │
          └────────────┴────────────┴────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 2: ORCHESTRATION (Logic, Routing, Timing)        │
│                    ⚙️ n8n                               │
│  • Route messages (WhatsApp → SMS fallback)            │
│  • Decide when to message                             │
│  • Transform payloads                                 │
│  • Trigger ERPNext actions                            │
│  • Handle retries, failures, timeouts                 │
│  • Glue Meta, SMSLeopard, M-Pesa, webhooks            │
│  ❌ NOT: Source of truth, long-term storage            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 1: SYSTEM OF RECORD (Truth, Money, Compliance)   │
│                  🧠 ERPNext                             │
│  • Customers (phone number = primary key)              │
│  • Orders / invoices                                   │
│  • Products & price lists                              │
│  • Payments (M-Pesa refs)                              │
│  • Vendors / merchants                                 │
│  • Audit logs & permissions                            │
│  • Regulatory data (KRA, VAT)                          │
│  ✅ Truth, Money, Customers, Compliance                 │
└─────────────────────────────────────────────────────────┘
```

---

## Why This Layering Works

### Global Pattern (India, Brazil, Nigeria, Kenya)

**Indian WhatsApp Commerce Platforms:**
- Channels: WhatsApp, SMS, USSD
- Orchestration: Custom middleware (like n8n)
- System of Record: ERP-like core (often custom, but same concept)

**Brazilian Chat-Commerce Stacks:**
- Channels: WhatsApp, SMS
- Orchestration: Zapier/Make.com or custom
- System of Record: ERPNext or custom ERP

**Nigerian Agent Networks:**
- Channels: WhatsApp, SMS, USSD
- Orchestration: n8n or similar
- System of Record: ERPNext or custom ledger

**Kenyan Banks (Co-op Bank, etc.):**
- Channels: WhatsApp, SMS, USSD
- Orchestration: Middleware layer
- System of Record: Core banking system

**Pattern**: All separate channels from orchestration from truth.

---

## Layer 1: System of Record (ERPNext)

### What ERPNext Should Own (Non-Negotiable)

**Core Entities:**
- **Customers** (phone number = primary key)
- **Orders / Invoices**
- **Products & Price Lists**
- **Payments** (M-Pesa refs, reconciliation)
- **Vendors / Merchants**
- **Agents** (human operators)
- **Audit Logs & Permissions**
- **Regulatory Data** (KRA, VAT)

**Why ERPNext for Nairobi:**
- Kenyan commerce is ledger-first, not app-first
- WhatsApp conversations come and go, records must persist
- You will eventually need:
  - Reconciliation
  - Dispute resolution
  - Merchant trust
  - Compliance (eTIMS, KRA)

**What ERPNext Should NOT Do:**
- ❌ Real-time workflow orchestration
- ❌ Async messaging retry logic
- ❌ Fallback routing (WhatsApp → SMS)
- ❌ External API glue (Meta, SMSLeopard, etc.)

**ERPNext decides what happened, not how messages flow.**

---

## Layer 2: Orchestration (n8n)

### What n8n Should Do

**Core Responsibilities:**
- Route messages (WhatsApp → SMS fallback)
- Decide when to message (24h windows, retry logic)
- Transform payloads (webhook → ERPNext format)
- Trigger ERPNext actions (create order, update payment)
- Handle retries, failures, timeouts
- Glue Meta, SMSLeopard, M-Pesa, webhooks
- Message classification (transactional, marketing, support)
- Fallback logic (WhatsApp failed → SMS)
- Cost control (suppress redundant messages)

**Why n8n Wins Here:**
- Visual logic = faster iteration as solo dev
- Self-hosted (critical for cost + control)
- Mature webhook + API handling
- Easy to swap providers later
- Free tier sufficient for MVP

**What n8n Should NOT Do:**
- ❌ Be the source of truth (customers, orders, payments)
- ❌ Store data long-term (beyond workflow state)
- ❌ Handle business accounting logic
- ❌ Permission management
- ❌ Compliance data storage

**n8n decides how messages flow, not what the business state is.**

---

## Layer 3: Channels (Replaceable)

### Channel Priority Rules

**Message Type → Channel Priority:**

| Message Type | Channel Priority | Fallback |
|--------------|------------------|----------|
| OTP / Auth | SMS | None (SMS is final) |
| Payment Confirmation | WhatsApp → SMS | If WhatsApp fails |
| Order Updates | WhatsApp → SMS | If WhatsApp fails |
| Support | WhatsApp | None (WhatsApp only) |
| Promotions | WhatsApp (opt-in only) | None |
| Critical Failure | SMS | None (SMS is final) |

**Key Principle**: Channels change. Orchestration adapts. Records must never break.

**Why Channels Are Replaceable:**
- WhatsApp API can change (Meta policy)
- SMSLeopard pricing can change
- New channels emerge (USSD, voice, etc.)
- Provider switching (SMSLeopard → Meta direct)

**Design Rule**: Never put core logic inside channel-specific code (WhatsApp bots, SMS handlers).

---

## Core Principles (What Makes or Breaks You)

### 1. Phone Number is Primary Key

**Not email. Not username.**

**Canonical Identity**: `+2547XXXXXXXX`

**Everything hangs off this:**
- Customer
- Merchant
- Agent
- Orders
- Payments
- WhatsApp conversations
- SMS history

**Why This Matters:**
- WhatsApp, SMS, USSD, M-Pesa all align on phone number
- Avoid identity fragmentation
- Later KYC becomes possible without refactors

**Implementation in ERPNext:**
- Phone number is UNIQUE
- Phone number is INDEXED
- Phone number is IMMUTABLE (except admin repair)

---

### 2. Opt-In, Consent & Trust (WhatsApp Punishes Mistakes)

**You must track consent explicitly.**

**Store:**
- Opt-in source (order, USSD, checkbox, QR, agent)
- Timestamp
- Channel (WhatsApp / SMS)
- Purpose (transactional, marketing)

**Rules:**
- **Transactional** = implied consent (order updates, payment confirmations)
- **Marketing** = explicit consent (promotions, newsletters)

**Design Pattern:**
- WhatsApp first (better UX, lower cost)
- SMS fallback (reliability)
- Never market via SMS unless explicitly opted in

**This Protects:**
- Your Meta account (no blocks)
- Your sender IDs (no suspension)
- Your brand (no spam reputation)

**Database Schema (ERPNext):**
```python
# Consent DocType
consent = {
  'phone': '+2547XXXXXXXX',
  'channel': 'whatsapp',  # or 'sms'
  'purpose': 'transactional',  # or 'marketing'
  'source': 'order_placed',  # how consent obtained
  'timestamp': '2026-01-09T14:30:00Z',
  'status': 'active',  # or 'revoked'
}
```

---

### 3. Message Taxonomy (Don't Treat All Messages the Same)

**Create a message classification system early.**

**Message Types:**

| Type | Channel Priority | Requires Consent | Fallback |
|------|------------------|------------------|----------|
| OTP / Auth | SMS | No (transactional) | None |
| Payment Confirmation | WhatsApp → SMS | No (transactional) | SMS |
| Order Updates | WhatsApp → SMS | No (transactional) | SMS |
| Support | WhatsApp | No (transactional) | None |
| Promotions | WhatsApp | Yes (marketing) | None |
| Critical Failure | SMS | No (transactional) | None |

**This Classification Should Live in n8n Logic, Not Hardcoded.**

**Enables:**
- Swap providers (SMSLeopard → Meta)
- Control cost (suppress non-critical messages)
- Stay compliant (respect opt-ins)
- Fallback routing (WhatsApp → SMS)

---

### 4. Fallback & Failure Strategy (Kenya Reality)

**Assume:**
- WhatsApp delivery sometimes fails
- Data bundles run out
- Phones go offline
- Users change devices

**Required Fallback Logic (n8n):**

```
1. Send WhatsApp
   ↓
2. Wait for delivery receipt (timeout: 60 seconds)
   ↓
3. If delivered ✅ → Done
   ↓
4. If not delivered ❌ → Send SMS
   ↓
5. Log both outcomes (ERPNext audit log)
```

**Never retry blindly.**

**Why:**
- Infinite retries get your WhatsApp number flagged
- SMS saves the transaction
- Logs save disputes

**This is core n8n logic, not optional.**

---

### 5. Payments & Reconciliation (M-Pesa is Not Optional)

**Even if you start small, design for reconciliation now.**

**Store (ERPNext):**
- M-Pesa receipt number
- Amount
- Phone number
- Timestamp
- Order reference
- Transaction status (pending, confirmed, failed)

**Golden Rule**: **Money is truth. Messages are noise.**

**ERPNext should always be able to answer:**
- Who paid?
- For what?
- When?
- Was it delivered?

**This is where many chat-commerce startups die.**

**Reconciliation Flow (n8n → ERPNext):**
```
1. M-Pesa webhook received (n8n)
   ↓
2. Extract: receipt_number, amount, phone, timestamp
   ↓
3. Query ERPNext: Find matching order by phone + amount (±50 KSh tolerance)
   ↓
4. If match found → Update ERPNext: payment_status = 'confirmed'
   ↓
5. If no match → Log to ERPNext: DAILY_LOG for manual review
   ↓
6. Send WhatsApp confirmation (n8n → WhatsApp API)
```

---

### 6. Human-in-the-Loop (Automation Alone Fails)

**Always provide escalation paths.**

**Bots are assistants, not replacements.**

**You Need:**
- Agent takeover (human can intercept any conversation)
- Conversation reassignment (transfer to different agent)
- Priority tagging (urgent, normal, low)
- Manual overrides (force send, force retry, suppress)

**Why:**
- Nairobi commerce is relational
- Trust beats automation
- Edge cases are common (payment mismatches, delivery issues, disputes)

**Implementation:**
- **ERPNext** = Permissioning (who can override, who can view)
- **n8n** = Routing (when to escalate, who to notify)
- **WhatsApp** = Interface (agent sees conversation, can respond)

---

### 7. Merchant & Agent Model (Future-Proofing)

**Even if you start with one business, design for many.**

**Core Entities (ERPNext):**

- **Merchant** (business owner)
- **Outlet / Stall** (physical location)
- **Agent** (human operator)
- **Product Catalog** (per merchant)
- **Price Lists** (per merchant, per location)

**This Lets You Later:**
- Onboard markets (Gikomba, Toi, Wakulima)
- Enable agent-assisted selling
- Do B2B ordering (merchant-to-merchant)
- Add commissions (platform fee per trade)

**Don't hardcode "single business" assumptions.**

**Database Schema (ERPNext):**
```python
# Merchant DocType
merchant = {
  'name': 'Amina Fabrics',
  'phone': '+254712345678',
  'market': 'Eastleigh',
  'status': 'active',
}

# Agent DocType
agent = {
  'name': 'John Doe',
  'phone': '+254799999999',
  'merchant_id': 'MER001',
  'role': 'seller',  # or 'reviewer', 'admin'
  'permissions': ['view_orders', 'confirm_orders', 'override'],
}
```

---

### 8. Compliance & Auditability (You'll Need This)

**Sooner or later:**
- Banks will ask (for partnerships)
- Partners will ask (for integrations)
- Regulators will ask (for licensing)

**You Must Be Able to Show:**
- Message logs (who sent what, when)
- Consent logs (when user opted in, how)
- Payment trails (M-Pesa receipts, reconciliation)
- User actions (orders, confirmations, cancellations)
- Agent actions (overrides, manual edits)

**ERPNext already understands this world.**
**Rebuilding it later is painful.**

**Audit Log Schema (ERPNext):**
```python
# Audit Log DocType
audit_log = {
  'entity_type': 'order',  # or 'payment', 'message', 'consent'
  'entity_id': 'TR20260109001',
  'action': 'created',  # or 'updated', 'deleted', 'confirmed'
  'actor_type': 'system',  # or 'agent', 'customer'
  'actor_id': '+254700456789',
  'timestamp': '2026-01-09T14:30:00Z',
  'changes': {'status': {'from': 'pending', 'to': 'confirmed'}},
  'metadata': {'ip_address': '...', 'user_agent': '...'},
}
```

---

### 9. Cost Control Levers (Keep Margins Alive)

**WhatsApp costs scale fast. So you need controls.**

**Cost Control Logic (n8n):**

1. **Time-Window Consolidation** (24h conversations)
   - Track last inbound message per user
   - Use session messages (no template cost) within 24h window
   - Use templates (paid) only outside 24h window

2. **Message Suppression Rules**
   - Don't send duplicate messages
   - Suppress non-critical updates
   - Batch notifications (daily digest instead of per-event)

3. **Template Minimization**
   - Use fewer templates (each template = approval overhead)
   - Reuse templates across use cases
   - A/B test templates to optimize engagement

4. **Smart Routing** (SMS vs WhatsApp)
   - Use SMS for critical failures (lower cost than WhatsApp retry)
   - Use WhatsApp for updates (better UX)
   - Route by message type (OTP → SMS, order update → WhatsApp)

**This logic belongs in n8n, not ERPNext.**

**Cost Per Trade Calculation:**
- WhatsApp conversations: 2.5 × KSh 0.75 = KSh 1.88
- SMS fallback (20% of messages): 0.5 × KSh 1.00 = KSh 0.50
- Platform costs: KSh 0.50
- **Total cost per trade: KSh 2.88**

---

### 10. Metrics That Actually Matter (Ignore Vanity Stats)

**Track (ERPNext + Analytics):**

**Business Metrics:**
- Cost per successful order
- Revenue per trade
- Platform margin per trade
- Conversion rate (message → order)
- Cart recovery rate (abandoned → paid)

**Operational Metrics:**
- Message cost per user
- Failed delivery rate (WhatsApp → SMS fallback)
- Human takeover rate (bot → agent)
- Repeat orders per phone number
- Payment reconciliation rate (auto-matched vs manual)

**Channel Metrics:**
- Delivery rate by channel (WhatsApp vs SMS)
- Engagement rate by channel
- Cost per message by channel
- Response time by channel

**Not Track (Vanity Metrics):**
- ❌ Message volume alone
- ❌ Bot response count alone
- ❌ Open rates alone (without conversion)
- ❌ Template usage count (without engagement)

**These metrics guide when to automate more vs add humans.**

---

## What Existing Systems Get Wrong (Learn From This)

### ❌ Common Failures

**1. Chatbots without backends**
- Problem: No source of truth, no audit trail, no reconciliation
- Solution: ERPNext is backbone, bots are interface

**2. CRMs pretending to be ERPs**
- Problem: CRMs don't understand accounting, payments, compliance
- Solution: ERPNext handles business logic, CRM is customer data only

**3. SaaS-only automation**
- Problem: Margins die, data locked, pricing explodes at scale
- Solution: Self-hosted n8n, own your data in ERPNext

**4. WhatsApp-only logic**
- Problem: Single point of failure, no fallback
- Solution: Multi-channel (WhatsApp → SMS), orchestrated by n8n

**5. No SMS fallback**
- Problem: WhatsApp failures = lost transactions
- Solution: Automatic SMS fallback on WhatsApp timeout

**6. No reconciliation**
- Problem: Payment mismatches, disputes, fraud
- Solution: M-Pesa webhooks → ERPNext → automatic matching

**7. No consent records**
- Problem: Meta blocks your account, regulatory issues
- Solution: Track consent in ERPNext, enforce in n8n

---

## Data Flow Examples

### Example 1: Order Flow

```
1. Buyer sends WhatsApp message: "I want 2m red chiffon"
   ↓ (n8n webhook)
2. n8n classifies: message_type = 'order', priority = 'high'
   ↓
3. n8n parses order (OrderParser service)
   ↓
4. n8n creates order in ERPNext (POST /api/resource/Sales%20Order)
   ↓
5. ERPNext creates order, returns order_id
   ↓
6. n8n checks conversation window (24h from last message)
   ↓
7. If within window → Send session message to buyer (no template cost)
   If outside window → Send template to buyer (paid)
   ↓
8. n8n notifies seller (template: "new_order_to_seller")
   ↓
9. Seller replies: "CONFIRM"
   ↓ (n8n webhook)
10. n8n updates ERPNext: order_status = 'confirmed'
    ↓
11. n8n sends payment link to buyer (STK push)
    ↓
12. Buyer pays via M-Pesa
    ↓ (M-Pesa webhook → n8n)
13. n8n reconciles payment in ERPNext (match receipt to order)
    ↓
14. ERPNext updates: payment_status = 'confirmed'
    ↓
15. n8n sends confirmations (buyer + seller)
```

**Key Points:**
- n8n orchestrates the flow
- ERPNext stores the truth
- WhatsApp is the interface (replaceable)

---

### Example 2: Payment Reconciliation

```
1. M-Pesa webhook received (n8n)
   Payload: { receipt: 'QR3UQR4O', amount: 1000, phone: '+254700456789', timestamp: '...' }
   ↓
2. n8n extracts: receipt_number, amount, phone, timestamp
   ↓
3. n8n queries ERPNext: Find order by phone + amount (±50 KSh tolerance)
   GET /api/resource/Sales%20Order?filters=[["customer_phone", "=", "+254700456789"], ["total_amount", "between", 950, 1050]]
   ↓
4. If match found (one order):
   n8n updates ERPNext:
   PUT /api/resource/Sales%20Order/TR20260109001
   { payment_status: 'confirmed', mpesa_ref: 'QR3UQR4O', paid_at: '...' }
   ↓
5. If no match or multiple matches:
   n8n logs to ERPNext: DAILY_LOG
   { event_type: 'payment_mismatch', details: '...', requires_review: true }
   ↓
6. n8n sends WhatsApp confirmation (buyer + seller)
```

**Key Points:**
- n8n handles the matching logic
- ERPNext stores the payment record
- Logs go to ERPNext for audit trail

---

### Example 3: Fallback (WhatsApp → SMS)

```
1. n8n sends WhatsApp message (order confirmation)
   ↓
2. n8n waits for delivery receipt (timeout: 60 seconds)
   ↓
3. If delivered ✅:
   Log to ERPNext: message_log
   { channel: 'whatsapp', status: 'delivered', message_id: '...' }
   Done.
   ↓
4. If not delivered ❌ (timeout or failed):
   Log to ERPNext: message_log
   { channel: 'whatsapp', status: 'failed', reason: 'timeout' }
   ↓
5. n8n checks message type (classification)
   If transactional → Send SMS fallback
   If marketing → Don't fallback (respect opt-in)
   ↓
6. n8n sends SMS via provider (e.g., AfricasTalking, SMSLeopard)
   ↓
7. Log to ERPNext: message_log
   { channel: 'sms', status: 'sent', fallback_reason: 'whatsapp_timeout' }
```

**Key Points:**
- n8n decides fallback logic
- ERPNext logs all attempts
- Channels are replaceable (swap SMS provider easily)

---

## Implementation Checklist (Solo Dev)

### ✅ Cursor Pro Best Practices

**1. Lock Architecture in Text**
- Create `/docs/architecture.md` (this file)
- Include: System layers, data ownership rules, message taxonomy, fallback rules
- Use as source of truth: "Reject changes that violate architecture.md"

**2. Prompt Cursor with Constraints, Not Tasks**
- ❌ Bad: "Build WhatsApp handler"
- ✅ Good: "Design WhatsApp webhook handler that is stateless, idempotent, logs to ERPNext, never sends messages directly (n8n only)"

**3. Generate Contracts Before Code**
- Always generate: Webhook payload schemas, ERPNext API contracts, n8n input/output shapes
- Then code to those contracts

**4. Use Cursor for Diff-Review**
- After every major change: "Review this diff and flag hidden coupling, state leakage, or scaling risks"

---

### ✅ n8n Best Practices

**5. Every Workflow Must Start with Classifier Node**
- First node answers: Message type? Channel? Priority? Is fallback allowed?
- Never let logic "emerge" mid-workflow

**6. One Workflow = One Responsibility**
- ✅ Good: `classify_message`, `send_whatsapp`, `send_sms_fallback`, `log_message`, `reconcile_payment`
- ❌ Bad: `mega_workflow_final_v7`
- Composable workflows = sanity

**7. Store Zero Business Truth in n8n**
- n8n should: Pass IDs, read state, trigger actions
- ERPNext stores: Customers, orders, payments, consent

**8. Build Retry + Timeout Logic on Day One**
- Every outbound message needs: Delivery timeout, retry limit, fallback rule, final failure state
- Assume failure is normal in Kenya

---

### ✅ Cross-Cutting Requirements

**9. Idempotency Keys Everywhere**
- Especially for: WhatsApp webhooks, M-Pesa callbacks, payment confirmations
- Duplicate messages will happen

**10. Time Windows Matter (Cost + UX)**
- WhatsApp pricing depends on conversation windows
- Track: Last inbound timestamp, conversation type
- Send fewer messages, smarter

**11. Build "Human Override" Hooks Early**
- Even if unused: Agent takeover flag, manual resend, manual message edit, message suppression
- Bots fail. Humans save revenue.

**12. Log Decisions, Not Just Events**
- ❌ Don't just log: "SMS sent"
- ✅ Log: "WhatsApp failed → SMS fallback chosen due to timeout"
- This is gold for debugging and trust

---

## What This Architecture Enables Later (Your Moat)

**Because of this layering, you can later add:**

**AI & Automation:**
- AI copilots (not full bots) - intent classification, context summarization
- Voice (IVR / WhatsApp voice) - voice note transcription, IVR routing
- Predictive routing (ML-based intent detection)

**Financial Services:**
- Credit scoring (based on order history, payment behavior)
- Supplier financing (merchant credit, inventory loans)
- Embedded finance (buy now pay later, insurance)

**Scale Features:**
- Agent apps (mobile app for reviewers/agents)
- Vendor dashboards (self-service merchant portal)
- Inventory pooling (multi-merchant inventory sharing)
- Cross-border trade (import/export workflows)

**Compliance & Integration:**
- Government integrations (eTIMS, KRA, NTSA)
- NGO programs (distribution, subsidies)
- Bank partnerships (payment rails, credit)

**Without rewriting your core.**

**This is why proper layering matters - it's future-proof.**

---

## Mental Model to Keep You Sharp

**If something feels hard, you're probably putting logic in the wrong layer:**

- **Cursor** = Thinking accelerator
- **n8n** = Decision conveyor belt
- **ERPNext** = Truth ledger
- **WhatsApp/SMS** = Replaceable skin

**Architecture Decision Tree:**
```
Is it business truth (customer, order, payment, consent)?
→ ERPNext

Is it flow logic (routing, retry, fallback, timing)?
→ n8n

Is it channel-specific (WhatsApp vs SMS vs USSD)?
→ n8n (channel abstraction layer)

Is it user interface (buttons, templates, flows)?
→ WhatsApp/SMS (templates, flows)
```

---

## Final Solo-Dev Rule

**If it feels clever, it's probably fragile.**
**If it feels boring, it will scale.**

**Examples:**
- ❌ Clever: "Let's build AI chatbot in WhatsApp directly"
- ✅ Boring: "Let's store orders in ERPNext, route messages via n8n"

- ❌ Clever: "Let's use Redis as our database"
- ✅ Boring: "Let's use ERPNext Postgres as our database"

- ❌ Clever: "Let's skip consent tracking for now"
- ✅ Boring: "Let's track consent from day one"

---

## References

- **Trade Facilitator Architecture**: [`TRADE_FACILITATOR_ARCHITECTURE.md`](./architecture/TRADE_FACILITATOR_ARCHITECTURE.md)
- **Integration Capabilities**: [`INTEGRATION_CAPABILITIES.md`](./INTEGRATION_CAPABILITIES.md)
- **Build Plan**: [`BUILD_PLAN.md`](./core/BUILD_PLAN.md) - Stage-gated execution plan
- **Lifecycle Stages**: [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) - 5-stage maturity model

---

## Next Steps

1. **Design ERPNext DocTypes** (Customer, Order, Payment, Consent, Audit Log)
2. **Design n8n Workflows** (classify_message, send_whatsapp, send_sms_fallback, reconcile_payment)
3. **Define Message Taxonomy** (transactional vs marketing, channel priority, fallback rules)
4. **Map Data Ownership** (what lives in ERPNext vs n8n vs external systems)

---

**Last Updated**: 2026-01-09  
**Status**: Architecture defined, implementation aligned  
**Next Review**: After ERPNext integration (Week 5-8)

