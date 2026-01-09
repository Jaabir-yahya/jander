# Architecture & System Design

**Tech stack, data schema, integrations, and technical decisions.**

> **Note:** This document is referenced by `.cursor-rules` for AI-assisted development. Always update this file when making architectural changes.

**Reference**: This document supports the 5-stage lifecycle in [`BUILD_PLAN.md`](./BUILD_PLAN.md). See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for detailed stage definitions.

**WaaS Architecture**: For the three-layer architecture (ERPNext → n8n → Channels), see [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md). This document focuses on the current Trade Facilitator implementation.

---

## Stage-Gated Architecture Evolution

### Stage 1: Foundation (Weeks 1–2)
- **Backend:** Google Sheets (Data capture, fast iteration)
- **Automation:** n8n (Simple triggers, webhook → database)
- **WhatsApp:** SMSLeopard WhatsApp Business API (Webhook gateway)
- **Payment:** M-Pesa Daraja (Sandbox → Live STK push)
- **Template Governance:** Template registry system (5+ pre-approved templates)
- **Delivery Monitoring:** WhatsApp API delivery status tracking (target: 90%+)

### Stage 2: Containment (Weeks 3–4)
- **Backend:** Google Sheets (Context storage, conversation history)
- **Automation:** n8n (Intent routing, bot responses)
- **WhatsApp:** SMSLeopard WhatsApp Business API (Bot responses, human handoff)
- **Payment:** M-Pesa Daraja (Retry logic, payment links)
- **Intent Detection:** Keyword-based classification (Stage 2), ML-enhanced (Stage 5)

### Stage 3: Integration (Weeks 5–8)
- **Backend:** Supabase (Primary database, Postgres)
- **Migration:** Whalesync (Google Sheets ↔ Supabase dual-write)
- **Automation:** n8n (Multi-step funnels, post-purchase sequences)
- **WhatsApp:** SMSLeopard WhatsApp Business API (Sequences, cart recovery)
- **Payment:** M-Pesa Daraja (Full reconciliation, retry logic)
- **ERP Integration:** ERPNext API bridge (Optional, Week 9+)

### Stage 4: Maturity (Weeks 9–12)
- **Backend:** Supabase + ERPNext/Frappe (Analytics DB, OMS)
- **Automation:** n8n (Analytics hooks, A/B testing)
- **WhatsApp:** SMSLeopard WhatsApp Business API (A/B tested templates)
- **Payment:** M-Pesa Daraja (Analytics tracking)
- **Template Backlog:** 10-15 templates per workflow domain (40-60 total)
- **Analytics:** Message → Action → Outcome tracking (see [`ANALYTICS_SCHEMA.md`](./ANALYTICS_SCHEMA.md))

### Stage 5: Predictive (Weeks 13+)
- **Backend:** Supabase + ERPNext (Predictive data, AI integration)
- **Automation:** n8n (AI integration, proactive triggers)
- **WhatsApp:** SMSLeopard WhatsApp Business API (Proactive notifications)
- **Payment:** M-Pesa Daraja (Predictive retry logic)
- **AI Integration:** Embeddings-based intent classification, context summarization

---

## Backend Comparison & Migration Strategy

| Backend | Best For | Setup Time | Cost | Scale Limit | Handoff to DB |
|---------|----------|------------|------|-------------|---------------|
| **Google Sheets** | Weeks 1–2 pilot; <500 orders | 5 mins | Free | 5M cells (~50K orders) | Whalesync sync to Supabase |
| **Airtable** | Weeks 2–4; visual collaboration; forms | 15 mins | Free (500 rec); $20+/mo | 125K records (Pro) | Airtable API → Supabase |
| **Supabase** | Weeks 5+; production backend; auth | 30 mins | Free (50K users, 500MB); $25+/mo | 8GB (Pro); unlimited (Enterprise) | Native Postgres; ERPNext-ready |

**Recommendation:**  
→ Start **Google Sheets** (Week 1–2, zero setup cost)  
→ Migrate to **Airtable** (Week 3–4) once forms + multi-staff collaboration needed  
→ Graduate to **Supabase** (Week 5+) when WhatsApp API + M-Pesa webhooks require database reliability

---

## Data Schema

### Minimal Schema (Google Sheets v1)

**Sheet 1: TRADERS**
```
├─ trader_id (auto-generate, e.g., T001)
├─ name (text: "Amina Fabrics")
├─ phone (text: "+254700123456")
├─ market (text: "Gikomba" | "Eastleigh")
├─ products_count (number: how many items they sell)
├─ status (text: "Active" | "Inactive")
├─ joined_date (date)
```

**Sheet 2: PRODUCTS (Catalog)**
```
├─ product_id (auto-generate, e.g., P001)
├─ trader_id (reference to TRADERS.trader_id)
├─ name (text: "Cotton Chiffon, 2m")
├─ price_kes (number: 500)
├─ description (text: "Red chiffon, per 2m roll")
├─ image_url (link to WhatsApp media or Google Drive)
├─ variant_json (raw: {"color": ["red", "blue"], "size": ["2m", "3m"]})
├─ active (yes/no: for archiving)
```

**Sheet 3: ORDERS**
```
├─ order_id (auto-generate, e.g., O001)
├─ order_date (date/time)
├─ trader_id (reference)
├─ customer_name (text)
├─ customer_phone (text)
├─ product_id (reference)
├─ quantity (number)
├─ unit_price (number)
├─ total_kes (formula: quantity × unit_price)
├─ payment_status (text: "Pending" | "Confirmed")
├─ payment_ref (text: "M-Pesa till ref or screenshot")
├─ dispatch_status (text: "Not Ready" | "Ready" | "Dispatched" | "Delivered")
├─ dispatch_date (date/time or blank)
├─ notes (text: "Voice note summary" or "Customer delivery address")
```

**Sheet 4: PAYMENTS (M-Pesa Reconciliation)**
```
├─ payment_id (auto-generate)
├─ order_id (reference)
├─ trader_id (reference)
├─ amount_kes (number)
├─ mpesa_ref (text: till transaction ref)
├─ mpesa_timestamp (date/time: when till recorded it)
├─ matched_to_order (yes/no)
├─ matched_date (date/time: when you matched it)
├─ payment_type (text: "Till" | "Paybill" | "B2C" | "COD")
├─ status (text: "Pending" | "Confirmed" | "Failed")
```

**Sheet 5: DAILY_LOG (for disputes & audits)**
```
├─ log_id (auto-generate)
├─ date (date)
├─ trader_id (reference)
├─ event_type (text: "Chat Missed" | "Order Captured" | "Payment Mismatch" | "Dispute")
├─ details (text: description)
├─ resolved (yes/no)
```

**Total: ~60 columns across 5 sheets. Minimal but sufficient.**

### Supabase Schema (Week 5+)

```sql
-- Traders
CREATE TABLE traders (
  trader_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  market TEXT,
  status TEXT DEFAULT 'Active',
  joined_date TIMESTAMPTZ DEFAULT NOW()
);

-- Products
CREATE TABLE products (
  product_id TEXT PRIMARY KEY,
  trader_id TEXT REFERENCES traders(trader_id),
  name TEXT,
  price_kes DECIMAL,
  description TEXT,
  active BOOLEAN DEFAULT TRUE
);

-- Orders
CREATE TABLE orders (
  order_id TEXT PRIMARY KEY,
  order_date TIMESTAMPTZ DEFAULT NOW(),
  trader_id TEXT REFERENCES traders(trader_id),
  customer_name TEXT,
  customer_phone TEXT,
  product_id TEXT REFERENCES products(product_id),
  quantity INT,
  total_kes DECIMAL,
  payment_status TEXT DEFAULT 'Pending',
  dispatch_status TEXT DEFAULT 'Not Ready'
);

-- Payments
CREATE TABLE payments (
  payment_id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(order_id),
  amount_kes DECIMAL,
  mpesa_ref TEXT,
  status TEXT DEFAULT 'Pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## WhatsApp Integration

### Automation-First Architecture

**System Type:** Pure automation infrastructure with WhatsApp as UX (NOT bulk messaging)

**Architecture:**
```
WhatsApp (Trader Interface)
    ↓
SMSLeopard (Webhook Gateway - Kenya Meta Partner)
    ↓
n8n (Automation Engine - Core Infrastructure)
    ↓
├─ Google Sheets (Order Database)
├─ Daraja (M-Pesa Payment Webhook)
├─ Image OCR (Receipt Processing)
├─ Audio Transcription (Voice Notes)
└─ Invoice Generation
```

**Why SMSLeopard (Not Direct Meta):**

**Current Choice (SMSLeopard):**
- Direct Meta WhatsApp Business Cloud API access is **restricted in Kenya (2025-2026)**
- SMSLeopard = Official Meta Business Solution Provider (BSP) with local Kenya support
- Same API spec as Meta's WhatsApp Business API - drop-in replacement
- Webhook-native architecture built for automation (not just bulk messaging)
- Faster template approval through BSPs
- Local support team for faster issue resolution
- Cost: KSh 1,999/mo starter (10K messages) - platform cost, not per-message

**When to Use Direct Meta:**
- If Meta direct access becomes available in Kenya
- If you need advanced features only available in direct API
- If cost optimization requires direct API (lower per-message costs at scale)
- If building for global deployment beyond Kenya

**Migration Path:** Architecture supports both providers via environment variable. Same webhook structure, same API patterns. Swap provider by changing `WHATSAPP_PROVIDER` env var.

**Provider Selection:**
```javascript
// apps/whatsapp-business/config.js
const WHATSAPP_PROVIDER = process.env.WHATSAPP_PROVIDER || 'smsleopard';

const providers = {
  smsleopard: {
    apiBaseUrl: 'https://api.smsleopard.co.ke',
    webhookUrl: 'https://api.smsleopard.co.ke/webhook',
    // Same API spec as Meta
  },
  meta: {
    apiBaseUrl: 'https://graph.facebook.com/v18.0',
    webhookUrl: 'https://graph.facebook.com/v18.0/webhook',
    // Meta's official API
  }
};
```

**Setup:**
1. Sign up at https://smsleopard.co.ke/whatsapp-business.html
2. Get API Token, Phone Number ID, Webhook URL
3. Configure `.env`:
   ```
   WHATSAPP_PROVIDER=smsleopard
   WHATSAPP_TOKEN=xxx
   PHONE_NUMBER_ID=yyy
   SMSLEOPARD_WEBHOOK_URL=https://api.smsleopard.co.ke/webhook
   SMSLEOPARD_API_BASE_URL=https://api.smsleopard.co.ke
   ```

**Automation Chain:**
- SMSLeopard webhook → n8n trigger (zero lag)
- n8n processes: text/image/audio → order extraction
- Google Sheets: Order database
- Daraja webhook → n8n payment matching
- SMSLeopard API: Send confirmations

**Cost:** KSh 1,999/mo starter (10K messages) - platform cost, NOT per-message
**Migration Path:** If Meta direct access available later, same webhook structure, swap API endpoints

---

### SMSLeopard WhatsApp Business API Setup

1. **Sign Up for SMSLeopard**  
   - Go to https://smsleopard.co.ke/whatsapp-business.html
   - Sign up with business name + KRA PIN
   - Get instant sandbox access

2. **Get Credentials**  
   - API Token (from dashboard)
   - Phone Number ID (assigned number)
   - Webhook configuration URL (set after n8n is ready)

3. **Configure Webhook**  
   - Point SMSLeopard webhook to n8n webhook endpoint (use ngrok for local)
   - Webhook will forward all WhatsApp messages to n8n for processing
   - Handle message types: text, image, voice, document

4. **Test Webhook**  
   - Send test WhatsApp message
   - Verify n8n receives webhook payload
   - Check message data extraction

5. **Message Templates**  
   - Submit templates via SMSLeopard dashboard for approval
   - Example templates:
     - "Order Confirmed: {{order_id}}, Total KSh {{total}}, Pay to {{till_number}}"
     - "Payment Received! Your order {{order_id}} is ready for dispatch."
     - "Your delivery is on the way. Track here: {{delivery_url}}"

**Cost:** KSh 1,999/mo starter (10K messages) - covers Week 12 goal

### Template Governance System (Stage 1 Requirement)

**Reference**: See [`TEMPLATE_REGISTRY.md`](./TEMPLATE_REGISTRY.md) for complete template registry.

**Template Approval Workflow**:
1. Create template content with variables
2. Submit to SMSLeopard/Meta dashboard for approval
3. Track approval status (target: < 24 hours)
4. Version control (track template versions: v1, v2, v3...)
5. Usage tracking (log every template usage)
6. Performance monitoring (delivery rate, engagement rate, conversion rate)

**Stage 1 Templates** (5 core templates):
- `order_confirmation` - Order created confirmation
- `payment_request` - STK push payment request
- `payment_confirmation` - Payment matched confirmation
- `order_status` - Order status response
- `support_acknowledgment` - Support request acknowledgment

**Stage 2 Templates** (3 critical workflows):
- `order_tracking_response` - Auto-response to "Where is my order?"
- `payment_link_response` - Auto-response to "I want to pay"
- `ticket_triage_acknowledgment` - Support ticket acknowledgment

**Stage 3 Templates** (Post-purchase sequences):
- `dispatch_notification` - Order dispatched notification
- `delivery_confirmation` - Order delivered confirmation
- `review_request` - Review request (24hrs after delivery)
- `payment_reminder_1/2/final` - Cart recovery sequence (24hrs, 48hrs, 72hrs)

**Stage 4 Templates** (10-15 per domain):
- Orders: 5 templates (confirmation, reminder, payment link, dispatch, delivery)
- Payments: 3 templates (STK push, confirmation, failure)
- Support: 5 templates (acknowledgment, escalation, resolution, follow-up, satisfaction)
- Returns: 2 templates (initiation, refund confirmation)

**Total**: 40-60 templates by Stage 4 (exceeds research benchmark of 15 minimum)

### Legacy: Meta WhatsApp Business Cloud API (Not Available in Kenya)

> **Note:** Direct Meta WhatsApp Cloud API access is restricted in Kenya (2025-2026). Use SMSLeopard (above) instead. The following section is kept for reference if Meta access becomes available.

### Message Templates

**Template 1: Order Confirmation**
```
Hi {{customer_name}}, your order #{{order_id}} is confirmed.
Items: {{product_name}} × {{qty}}
Total: KSh {{total}}
Pay to: {{till_number}} ({{trader_name}})
[Link to tracking](https://...)
Asante!
```

**Template 2: Payment Alert**
```
✅ Payment received! Order {{order_id}} is ready for delivery.
Dispatch: {{dispatch_date_time}}
Rider: {{rider_name}}, {{rider_phone}}
Track live: {{link}}
```

**Template 3: Weekly Broadcast**
```
🛍 New week, new arrivals! Check our latest:
- {{product_name1}}: KSh {{price1}} [📸](link)
- {{product_name2}}: KSh {{price2}} [📸](link)
Reply with item # to order or call {{trader_phone}}.
```

---

## M-Pesa Integration

### Daraja API Setup

1. **Get Till / Paybill Number**
   - Apply to Safaricom (can take 1–2 weeks)
   - For pilot: Use personal **Buy Goods Till** (faster, ~3 days)

2. **Register on Daraja Portal**
   - https://developer.safaricom.co.ke
   - Create app; get Consumer Key & Consumer Secret

3. **Test C2B Flow (Sandbox)**
   ```
   API Endpoint: https://sandbox.safaricom.co.ke/mpesa/c2b/v2/simulate
   Request body:
   {
     "ShortCode": "123456" (your till),
     "CommandID": "CustomerPayBillOnline",
     "Amount": "500",
     "Msisdn": "254700123456",
     "BillRefNumber": "O001" (your order_id)
   }
   ```

4. **Webhook for Payment Confirmation**
   - Set webhook URL in Daraja dashboard
   - Webhook receives transaction updates with MpesaReceiptNumber

5. **Go Live**
   - Submit business docs (KRA PIN, company registration)
   - Safaricom approves; activates live credentials

**Cost:** Free (Daraja); M-Pesa charges 0.5% per till transaction (capped ~KSh 3–4 per KSh 1K transaction)

### Payment Matching Logic

**Ideal Case (Webhook matching):**
```
M-Pesa webhook arrives → Extract MpesaReceiptNumber
→ Search ORDERS.order_id == MpesaReceiptNumber
→ Match found → Mark ORDERS.payment_status = "Confirmed"
→ Trigger dispatch workflow
```

**Fallback Case (Manual matching):**
```
Trader uploads screenshot → n8n OCR extracts amount + ref
→ Search ORDERS for amount within ±50 KSh
→ If one match, auto-confirm; if multiple, create row in DAILY_LOG for manual review
```

**Risk Mitigation:**
- **Same-day audit:** At 6 PM daily, pull till statement from M-Pesa merchant portal; compare to ORDERS
- **Alert on mismatch:** If payment received but no order, send trader alert
- **No write-offs:** If unmatched for 48 hrs, contact customer via WhatsApp

---

## Automation Workflows (n8n)

**Workflow 1: Order Capture → Confirmation Message**
```
Trigger: Google Sheet new row (Sheet: ORDERS)
→ Filter: payment_status == "Pending"
→ HTTP: POST to WhatsApp API
  Body: {
    "message_type": "template",
    "to": {{customer_phone}},
    "template_name": "order_confirmation",
    "parameters": [{{order_id}}, {{total}}, {{till_number}}]
  }
→ Response: Mark message_sent = TRUE in sheet
```

**Workflow 2: M-Pesa Payment Match**
```
Trigger: M-Pesa Daraja webhook (new till transaction)
→ Extract: transaction_ref, amount, timestamp
→ Search: Google Sheet PAYMENTS for order with close amount
→ If match: Update ORDERS.payment_status = "Confirmed"
→ If no match: Create row in DAILY_LOG.event_type = "Payment Mismatch"
→ Send alert: "Payment KSh {{amount}} received but order not found. Check manually."
```

**Workflow 3: Auto-Archive Old Catalogs**
```
Trigger: Weekly (Monday 9 AM)
→ Google Sheet: Copy PRODUCTS.active = FALSE to ARCHIVE sheet
→ Delete from PRODUCTS
→ Send trader: "Old items archived. Update prices this week?"
```

**Cost:** n8n free tier (unlimited workflows)

---

## Migration Paths

### Sheets → Supabase (Week 5)

1. **Create Supabase Project**
   - Go to https://supabase.com
   - Create project (free tier: 500MB, 50K monthly users)

2. **Define Tables**
   - Use schema above (CREATE TABLE statements)

3. **Use Whalesync to Sync**
   - Go to https://whalesync.com (free trial)
   - Authorize Google Sheets + Supabase
   - Map columns: TRADERS sheet → traders table, etc.
   - Enable bidirectional sync

4. **Update n8n Workflows**
   - Redirect triggers from "Google Sheets" to "Supabase" queries
   - Example: Trigger: Supabase realtime subscription (orders table)

**Cost:** Supabase free tier + Whalesync ($15–29/mo)

### Supabase → ERPNext (Week 9+, Optional)

**Step 1: Set Up ERPNext on Frappe Cloud**
- https://frappe.cloud
- Create instance (KES 2K/month for small SaaS)
- Install M-Pesa module

**Step 2: API Bridge (Supabase → ERPNext)**
```
Supabase trigger: ORDER.status = "Confirmed"
→ HTTP POST to ERPNext API
  {
    "doctype": "Sales Order",
    "customer": {{customer_name}},
    "items": [{
      "item_code": {{product_id}},
      "qty": {{quantity}},
      "rate": {{unit_price}}
    }],
    "order_id": {{order_id}}
  }
→ ERPNext auto-creates invoice, tracks stock, generates eTIMS doc
```

**Step 3: Traders Access ERPNext Dashboard (Optional)**
- Lightweight interface (not full ERP UI)
- Shows: "Orders this week: 5, Revenue: KSh 10K, Stock: Fabrics 50m"
- No navigation to inventory adjustments, GL, etc.

---

## Template Governance Architecture

### Template Lifecycle Management

**Stage 1**: Foundation templates (5 core templates)
- Pre-approval workflow established
- Version control system
- Usage tracking per template
- Performance monitoring (delivery rate, engagement rate)

**Stage 2**: Containment templates (3 critical workflows)
- Intent-based template routing
- Context-aware template selection
- Bot response templates

**Stage 3**: Integration templates (Post-purchase sequences)
- Multi-message sequence templates
- Cart recovery templates
- Payment retry templates

**Stage 4**: Maturity templates (A/B testing framework)
- Template versioning with A/B tests
- Performance comparison (delivery, engagement, conversion)
- Optimization backlog (reduce steps, improve messaging)

**Stage 5**: Predictive templates (AI-assisted routing)
- Proactive notification templates
- Retention campaign templates
- Personalized template selection (based on customer tier, intent confidence)

### Template Performance Tracking

**Metrics Schema** (see [`ANALYTICS_SCHEMA.md`](./ANALYTICS_SCHEMA.md)):
- Delivery rate (target: 90%+)
- Engagement rate (clicks/opens per template)
- Conversion rate (message → order per template)
- Cost per template (if using per-message pricing)

**Database Schema** (Supabase):
```sql
CREATE TABLE template_registry (
  template_id TEXT PRIMARY KEY,
  template_name TEXT NOT NULL,
  category TEXT, -- 'orders', 'payments', 'support', 'returns'
  version TEXT DEFAULT 'v1',
  content TEXT NOT NULL,
  variables JSONB, -- Array of variable names
  approval_status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  approval_timestamp TIMESTAMPTZ,
  usage_count INT DEFAULT 0,
  delivery_rate DECIMAL, -- Percentage
  engagement_rate DECIMAL, -- Percentage
  conversion_rate DECIMAL, -- Percentage
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Security Considerations

- **API Keys:** Store securely (not hardcoded in scripts)
- **WhatsApp:** Verified Business account only
- **Row-Level Security:** Enable RLS in Supabase; traders can only see their own data
- **eTIMS Compliance:** Invoice generation templates reviewed for KRA compliance
- **Access Control:** Shared inbox with tags (not shared passwords); audit log of who did what
- **Template Approval:** Template approval workflow enforced (Stage 1 gate)

---

## Cursor AI Development Setup

This project uses `.cursor-rules` in the root directory to guide AI-assisted development. The rules file:
- References the 5 core documentation files (docs/*.md)
- Sets week-by-week context and tech stack
- Defines Nairobi-specific edge cases to handle
- Provides prompt templates for consistent development

**Key Rule:** Every code change must include:
1. Exact setup steps
2. Error handling (spotty 4G, voice notes, payment mismatches)
3. Test cases (happy path + error scenarios)
4. Migration path considerations
5. Documentation update instructions

**See `.cursor-rules` in project root for full AI development guidelines.**

---

## Integration Capabilities Reference

**For detailed integration capability requirements and test cases, see:**
- [`INTEGRATION_CAPABILITIES.md`](./INTEGRATION_CAPABILITIES.md) - Maximum capabilities required from each integration
- [`../tests/INTEGRATION_TESTS.md`](../tests/INTEGRATION_TESTS.md) - Comprehensive test cases for all integrations

**Key Capabilities Required:**
- Webhook verification & security (HMAC signatures)
- Idempotency keys (prevent duplicate processing)
- Error handling & retry (exponential backoff)
- Rate limiting & throttling (per-trader, per-workflow)
- Monitoring & alerting (system health, failures)
- Test data factories (automated test data generation)
- Environment management (dev/staging/prod)
- Logging & observability (structured logs, tracing)
- Backup & disaster recovery (automated backups)
- Multi-tenancy isolation (RLS policies verified)

**Last Updated:** 2026-01-09  
**Status**: Integration capabilities defined, implementation in progress

