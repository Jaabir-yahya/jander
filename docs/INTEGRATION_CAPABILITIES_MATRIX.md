# Integration Capabilities Matrix

**What Each Integration Must Support (MVP → Scale)**

Based on WaaS architecture, here are the **maximum capabilities required** from each integration layer.

**Reference**: This extends [`INTEGRATION_CAPABILITIES.md`](./INTEGRATION_CAPABILITIES.md) with a detailed capability matrix and testing checklist.

---

## LAYER 3: CHANNELS

### Meta (WhatsApp Business Cloud API)

**MUST-HAVE (Day 1):**
- ✅ Send template messages (transactional)
- ✅ Receive webhooks (inbound messages, delivery receipts)
- ✅ Extract conversation metadata (sender phone, message ID, timestamp)
- ✅ Send session messages (within 24h conversation window)
- ✅ Handle delivery receipts (delivered, read, failed status)

**SHOULD-HAVE (Week 3-4):**
- ✅ Send media messages (images, documents)
- ✅ Interactive messages (buttons, lists)
- ✅ Location data (if supporting location-based ordering)

**NICE-TO-HAVE (Later):**
- ✅ Catalog integration (product browsing)
- ✅ Click-to-WhatsApp ads (customer acquisition)
- ✅ Phone number quality (API-based phone validation)

**Max Required Capability**: Session messages + templates + webhooks + delivery receipts
**Cost at Scale**: KSh 0.75 per template + KSh 0 per session message

**Rejection Criteria**:
- ❌ Building custom WhatsApp bot (violates platform ToS, no API access to conversations)
- ❌ Storing conversations in n8n/ERPNext (violates data residency, use Meta's webhook logs)

---

### SMS Provider (SMSLeopard / Africa's Talking / Twilio)

**MUST-HAVE (Day 1):**
- ✅ Send SMS (text only)
- ✅ Receive webhooks (delivery receipts, inbound SMS)
- ✅ Sender ID support (business branding)
- ✅ Bulk SMS (batch sending for cost efficiency)

**SHOULD-HAVE (Week 3-4):**
- ✅ Scheduled SMS (send at specific time)
- ✅ SMS with links (click tracking optional)
- ✅ Delivery reports (detailed: pending, delivered, failed)

**NICE-TO-HAVE (Later):**
- ✅ USSD support (for offline users)
- ✅ Voice calls (OTP delivery via voice)
- ✅ SMS-to-Email gateway (legacy system integration)

**Max Required Capability**: Send + webhooks + sender ID + bulk + delivery reports
**Cost at Scale**: KSh 1.00 per SMS

**Recommended Provider (Kenya Context)**:
- **SMSLeopard** (best local pricing, Safaricom integration)
- **Africa's Talking** (broader feature set, USSD)
- Avoid: Twilio (expensive in Kenya)

**Rejection Criteria**:
- ❌ Provider doesn't support Kenya phone numbers
- ❌ No webhook support (can't track delivery)
- ❌ No bulk API (can't send cost-efficiently)

---

### USSD (Optional, but Recommended for MVP)

**MUST-HAVE (Week 2-3 if included):**
- ✅ Session management (multi-step flows)
- ✅ User input (numeric/text)
- ✅ Callback webhooks (user action → n8n)

**Why USSD Matters for Kenya:**
- Works on feature phones (no WhatsApp required)
- No data cost (USSD is free)
- High adoption in rural areas
- Fallback for areas with poor data connectivity

**Implementation Note:**
- USSD is stateful (session-based), not stateless like WhatsApp
- n8n handles state management
- ERPNext stores final outcomes

**Max Required Capability**: Multi-step sessions + webhooks + input handling
**Cost at Scale**: KSh 0.50 per USSD session (provider-dependent)

---

## LAYER 2: ORCHESTRATION (n8n)

### n8n Self-Hosted

**MUST-HAVE (Day 1):**
- ✅ Webhook receiver (inbound messages from WhatsApp, SMS, USSD)
- ✅ HTTP POST/GET (outbound to ERPNext, Meta, SMS provider)
- ✅ JSON parsing (extract phone, message, order details)
- ✅ Conditional logic (if/then/else routing)
- ✅ Wait nodes (timeout-based retry logic)
- ✅ Error handling (catch, log, fallback)

**SHOULD-HAVE (Week 2-3):**
- ✅ Loops (batch processing, multi-recipient sends)
- ✅ Code nodes (custom logic: regex parsing, calculations)
- ✅ Database nodes (read/write to external tables for session state)
- ✅ Scheduled triggers (cron: daily summaries, reconciliation)
- ✅ Workflow dependencies (trigger other workflows)

**NICE-TO-HAVE (Later):**
- ✅ AI nodes (intent classification, summarization)
- ✅ Advanced security (OAuth2 client credentials for ERPNext)

**Max Required Capability**: Webhooks + HTTP + JSON + conditionals + loops + error handling + scheduling
**Infrastructure**: Docker-based self-hosted (cost: ~KSh 5,000/month on DigitalOcean)

**Workflow Count (MVP):**
- `00_classify_message` (inbound classification)
- `01_send_whatsapp` (WhatsApp sender, with retry)
- `02_send_sms_fallback` (SMS fallback trigger)
- `03_reconcile_payment` (M-Pesa → ERPNext matching)
- `04_log_message` (audit trail to ERPNext)
- `05_notify_seller` (order notifications)
- `06_daily_reconciliation` (scheduled, end-of-day audit)

**Total Workflows**: 6-8 for MVP

**Rejection Criteria**:
- ❌ Using cloud n8n (no cost control, data lock-in)
- ❌ Building multi-step conversations in n8n (use ERPNext DocTypes instead)
- ❌ Storing customer data in n8n (data goes to ERPNext only)

---

## LAYER 1: SYSTEM OF RECORD (ERPNext)

### ERPNext Self-Hosted

**MUST-HAVE (Day 1):**
- ✅ Custom DocTypes (Customer, Order, Payment, Consent, Audit Log)
- ✅ REST API (read/write via n8n)
- ✅ Webhook API (for n8n to receive ERPNext events)
- ✅ Search/filter (find orders by phone, payment status, date range)
- ✅ Unique constraints (phone number is unique, immutable)
- ✅ User roles & permissions (agent vs merchant vs admin)
- ✅ Audit trail (automatic doctype change logging)

**SHOULD-HAVE (Week 3-4):**
- ✅ Custom reports (orders by merchant, revenue by day, payment reconciliation)
- ✅ Workflow states (order status: pending → confirmed → paid → delivered)
- ✅ Bulk operations (import CSV for batch orders, payments)
- ✅ Custom validations (order amount ≥ 100 KSh, phone format validation)

**NICE-TO-HAVE (Later):**
- ✅ Inventory management (product stock tracking)
- ✅ Accounting (double-entry ledger, VAT, KRA integration)
- ✅ CRM features (customer interaction history, segmentation)
- ✅ Permissions hierarchy (merchant can only see own orders)

**Max Required Capability**: DocTypes + REST API + search + unique constraints + audit trail + custom reports + permissions
**Infrastructure**: Docker-based self-hosted (cost: ~KSh 3,000/month on DigitalOcean)

**DocType Requirements (MVP):**

| DocType | Core Fields | Unique Constraints | Permissions |
|---------|-------------|-------------------|-------------|
| **Customer** | phone (PK), name, market, status | phone is UNIQUE | Public read, agent can create |
| **Merchant** | phone (PK), name, outlet, status | phone is UNIQUE | Merchant can self-edit |
| **Order** | order_id (PK), customer_phone (FK), merchant_id (FK), items, total_amount, status, created_at | None | Customer can view own, merchant can view own + team |
| **Payment** | payment_id (PK), order_id (FK), amount, mpesa_ref, status, paid_at, reconciled_at | mpesa_ref is UNIQUE per amount | Accounting can view all |
| **Consent** | consent_id (PK), phone (FK), channel, purpose, source, status, created_at | None | Privacy officer can audit |
| **Audit Log** | log_id (PK), entity_type, entity_id, action, actor_id, timestamp, changes, metadata | None | Admin read-only |

**API Endpoints Required:**

```
POST /api/resource/Sales%20Order                    (create order)
PUT /api/resource/Sales%20Order/{id}                (update order status, payment ref)
GET /api/resource/Sales%20Order?filters=[...]       (find order by customer_phone)
GET /api/resource/Customer/{phone}                  (get customer)
POST /api/resource/Payment                          (log M-Pesa payment)
POST /api/resource/Audit%20Log                      (log all actions)
GET /api/resource/Daily%20Reconciliation%20Report  (get payment mismatches)
```

**Rejection Criteria**:
- ❌ Using ERPNext Cloud (no control, compliance issues)
- ❌ Building conversation logic in ERPNext (use n8n instead)
- ❌ Using ERPNext to send messages directly (violates Orchestration layer)

---

## EXTERNAL INTEGRATIONS

### M-Pesa (Safaricom)

**MUST-HAVE (Day 1):**
- ✅ STK push (prompt user to enter PIN)
- ✅ Query API (check payment status)
- ✅ Webhook callback (payment confirmed/failed notification)
- ✅ Reconciliation API (daily statement download)

**How It Flows:**
```
n8n → M-Pesa STK Push → User enters PIN → M-Pesa webhook → n8n → ERPNext
```

**Max Required Capability**: STK push + webhooks + reconciliation
**Cost at Scale**: KSh 0.50 per STK push (Safaricom fee)

---

### Email (Transactional)

**MUST-HAVE (Week 2-3):**
- ✅ Send email (order confirmation, payment receipt)
- ✅ Templates (HTML, branded)
- ✅ Webhooks (delivery status optional)

**Recommended Provider:**
- SendGrid or Mailgun (affordable, reliable, Kenya-friendly)
- Or ERPNext built-in SMTP (requires email server setup)

**Max Required Capability**: Send templated emails + basic delivery tracking
**Cost at Scale**: Free (if self-hosted SMTP) or KSh 100-500/month (SendGrid)

---

## Integration Dependency Matrix

**What depends on what:**

```
Customer Message (WhatsApp/SMS)
    ↓
n8n (classifier_message workflow)
    ↓
    ├─→ ERPNext (create/update Order)
    │       ↓
    │   ERPNext (return order_id)
    │
    └─→ n8n (send_whatsapp workflow)
            ↓
            ├─→ Meta API (send message)
            │   ↓
            │   (delivery receipt)
            │   ↓
            └─→ n8n (receive webhook)
                    ↓
                    ERPNext (log message to audit trail)

Payment (M-Pesa)
    ↓
M-Pesa (customer pays)
    ↓
M-Pesa webhook → n8n
    ↓
n8n (reconcile_payment workflow)
    ↓
ERPNext (match payment to order, update status)
    ↓
n8n (send_confirmation workflow)
    ↓
Meta API / SMS Provider (send confirmation)
```

**Critical Path (Must Work Before MVP):**
1. n8n receives webhook (inbound message)
2. n8n creates order in ERPNext
3. n8n sends WhatsApp confirmation
4. M-Pesa webhook → n8n
5. n8n reconciles payment in ERPNext

---

## Integration Testing Checklist

Before marking each integration "done", verify:

### Meta (WhatsApp)

- [ ] Send template message (50 KSh order confirmation)
- [ ] Receive inbound message webhook
- [ ] Parse phone number, message text, timestamp
- [ ] Extract delivery receipt (delivered status)
- [ ] Handle timeout (no delivery receipt after 60 seconds)
- [ ] Test fallback to SMS (when WhatsApp fails)

### SMS Provider

- [ ] Send SMS to Kenya number
- [ ] Receive delivery receipt webhook
- [ ] Parse delivery status (pending, delivered, failed)
- [ ] Test bulk send (100 SMS batch)
- [ ] Verify cost (should be <KSh 1.50 per SMS including fees)

### n8n

- [ ] Webhook receives message, parses phone + text
- [ ] Creates order in ERPNext via API
- [ ] Sends WhatsApp back to customer
- [ ] Falls back to SMS on WhatsApp timeout
- [ ] Logs all actions to ERPNext audit trail
- [ ] Scheduled reconciliation runs daily

### ERPNext

- [ ] Create Customer by phone number (unique constraint)
- [ ] Create Order with order_id, customer_phone, items, total
- [ ] Update Order status (pending → confirmed → paid)
- [ ] Create Payment record with M-Pesa receipt
- [ ] Query Order by phone number (n8n uses this)
- [ ] Log all changes to Audit Log automatically
- [ ] Search: "Show all orders for +254700456789"

### M-Pesa

- [ ] Trigger STK push from n8n
- [ ] User confirms payment on phone
- [ ] M-Pesa webhook hits n8n endpoint
- [ ] n8n parses receipt number, amount, phone, timestamp
- [ ] n8n finds matching order in ERPNext (by phone + amount)
- [ ] n8n updates order: payment_status = 'confirmed'
- [ ] n8n sends WhatsApp confirmation to customer

### End-to-End (Full Trade)

- [ ] Customer sends WhatsApp: "I want 2m red chiffon"
- [ ] n8n receives, classifies, creates order in ERPNext
- [ ] n8n sends WhatsApp to seller: "New order: 2m red chiffon"
- [ ] Seller replies: "CONFIRM"
- [ ] n8n updates ERPNext: order_status = 'confirmed'
- [ ] n8n sends STK push to customer
- [ ] Customer pays KSh 500 via M-Pesa
- [ ] M-Pesa webhook hits n8n
- [ ] n8n reconciles payment in ERPNext
- [ ] n8n sends WhatsApp to both: "Payment confirmed, ready for pickup"
- [ ] Audit log shows all steps

---

## Maximum Capability Summary Table

| Integration | Layer | Must-Have | Should-Have | Cost/Month |
|-------------|-------|-----------|-------------|-----------|
| **Meta (WhatsApp)** | 3 | Templates, webhooks, sessions, delivery receipts | Media, interactive buttons | KSh 0-2,000 |
| **SMS (SMSLeopard)** | 3 | Send, webhooks, bulk, delivery reports | Scheduled, links | KSh 500-5,000 |
| **USSD** | 3 | Multi-step sessions, webhooks | Input validation | KSh 0-2,000 |
| **n8n** | 2 | Webhooks, HTTP, JSON, conditionals, loops, error handling, scheduling | Custom code, database nodes | KSh 5,000 |
| **ERPNext** | 1 | DocTypes, REST API, search, unique constraints, audit trail, permissions | Custom reports, workflows, validations | KSh 3,000 |
| **M-Pesa** | External | STK push, webhooks, reconciliation | Query API | KSh 0 (Safaricom fee) |
| **Email** | External | Send, templates | Delivery tracking | KSh 0-500 |

---

## Current Implementation Status

### ✅ Implemented

**Layer 3 (Channels):**
- ✅ WhatsApp integration (SMSLeopard/Meta abstraction)
- ✅ M-Pesa STK Push + B2C payouts
- ⚠️ SMS fallback (code exists, needs provider integration)
- ❌ USSD (not yet implemented)

**Layer 2 (Orchestration):**
- ✅ Trade Facilitator service (message routing)
- ✅ Conversation tracker (24h window management)
- ✅ Escrow manager (payment hold/release)
- ⚠️ n8n workflows (defined, not yet built)
- ❌ SMS fallback workflow (needs implementation)

**Layer 1 (System of Record):**
- ✅ Database schema (Supabase - 7 core tables + 6 WaaS tables)
- ✅ Phone number as primary key (enforced)
- ✅ Consent tracking (table created)
- ✅ Message logs (table created)
- ✅ Audit logs (table created)
- ⚠️ ERPNext integration (planned for Week 5-8)

### ⚠️ Gaps Identified

1. **SMS Provider Integration**
   - Code exists for SMS fallback logic
   - Need to integrate SMSLeopard/AfricasTalking API
   - Need to add SMS webhook handler

2. **n8n Workflows**
   - Workflows defined in `FIRST_7_WORKFLOWS.md`
   - Need to build actual n8n workflow JSON files
   - Need to test workflow execution

3. **ERPNext Integration**
   - Database schema ready (Supabase)
   - Need to create ERPNext DocTypes (Week 5-8)
   - Need to build ERPNext API bridge

4. **USSD Support**
   - Not yet implemented
   - Optional for MVP, recommended for scale

5. **Email Integration**
   - Not yet implemented
   - Should-have for Week 2-3

---

## Next Steps

1. **Audit current integrations** against this matrix
   - ✅ WhatsApp: Implemented (SMSLeopard/Meta abstraction)
   - ⚠️ SMS: Code exists, needs provider integration
   - ❌ USSD: Not implemented
   - ✅ M-Pesa: Implemented (STK Push + B2C)
   - ❌ Email: Not implemented
   - ⚠️ n8n: Workflows defined, not yet built
   - ⚠️ ERPNext: Schema ready, integration planned Week 5-8

2. **Identify gaps** (what's missing? what can be removed?)
   - Missing: SMS provider integration, n8n workflows, ERPNext integration, USSD, Email
   - Can remove: Nothing yet (all components serve a purpose)

3. **Prioritize** (MVP: WhatsApp + SMS + n8n + ERPNext + M-Pesa)
   - **Week 1**: WhatsApp + M-Pesa (✅ Done)
   - **Week 2**: SMS fallback integration
   - **Week 3**: n8n workflows (first 7)
   - **Week 5-8**: ERPNext integration
   - **Later**: USSD, Email

4. **Build contracts** (webhook schemas, API responses)
   - See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) (if exists)
   - Need to create webhook payload schemas
   - Need to create ERPNext API contracts

5. **Test E2E** before moving to next integration
   - See Integration Testing Checklist above
   - Run end-to-end test: Customer message → Order → Payment → Confirmation

---

## References

- **WaaS Architecture**: [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md)
- **Integration Capabilities**: [`INTEGRATION_CAPABILITIES.md`](./INTEGRATION_CAPABILITIES.md)
- **First 7 Workflows**: [`FIRST_7_WORKFLOWS.md`](./FIRST_7_WORKFLOWS.md)
- **Build Plan**: [`BUILD_PLAN.md`](./BUILD_PLAN.md)

---

**Last Updated**: 2026-01-09  
**Status**: Matrix defined, implementation audit complete, gaps identified  
**Next Review**: After n8n workflows built (Week 3)

