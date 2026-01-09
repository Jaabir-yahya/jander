# MVP Workflows: Final Implementation Plan

**Based on proven patterns from India, Brazil, Nigeria, and Kenya**

**Goal:** Map exactly what each workflow needs to do, covering both:
- **Max WhatsApp, Min Truth**: High automation, minimal database (early stage)
- **Min WhatsApp, Max Truth**: Lower automation, comprehensive database (mature stage)
- **All scenarios in between**

**Status:** Final MVP specification - ready for implementation  
**Last Updated:** January 9, 2026

---

## 🎯 Core Philosophy

**From Research:**
- **India**: Orchestration-first, database as truth, payment reconciliation automated
- **Brazil**: Native integrations, multi-rail payments, human-in-the-loop
- **Nigeria**: Phone number identity, consent tracking, fallback strategies
- **Kenya**: M-Pesa integration, eTIMS compliance, voice notes support

**Our Approach:**
- Start with solid foundations (database, orchestration, payment matching)
- Build workflows that scale from 1 trader to 100+
- Cover edge cases (low confidence, payment mismatches, offline scenarios)
- Make good decisions as solo dev (efficiency, maintainability, scalability)

---

## 📋 Workflow Architecture

### Three-Layer Pattern (Non-Negotiable)

```
Layer 3: Channels (WhatsApp, SMS, USSD)
    ↓
Layer 2: Orchestration (n8n workflows)
    ↓
Layer 1: System of Record (Supabase)
```

**Key Principle:** Workflows orchestrate, database stores truth.

---

## 🔄 Core Workflows (Priority Order)

### Workflow 0: Tenant Config Lookup ⭐ **FOUNDATION**

**Purpose:** Every workflow needs tenant credentials. This is the foundation.

**Input:**
- `tenant_id` (from webhook query param or message context)
- `phone` (optional, for seller lookup)

**Process:**
1. Extract `tenant_id` from input
2. If `tenant_id` missing, try to infer from `phone` (lookup seller)
3. Query `tenant_config` table in Supabase
4. Return tenant credentials (WhatsApp, M-Pesa, ERP, etc.)

**Output:**
- Tenant config object with all credentials
- Error if tenant not found

**Database:**
- Read: `tenant_config` table
- Read: `sellers` table (if inferring from phone)

**Why First:**
- Every other workflow depends on this
- Without tenant config, nothing works
- India pattern: Centralized config lookup

**Coverage:**
- ✅ Max WhatsApp: Uses tenant config for WhatsApp credentials
- ✅ Max Truth: Uses tenant config for database connections
- ✅ All scenarios: Works for both

---

### Workflow 1: Message Classification

**Purpose:** Route incoming messages to correct handler (order, inquiry, payment, support)

**Input:**
- WhatsApp webhook payload
- `tenant_id` (from webhook or Workflow 0)

**Process:**
1. Extract message content (text, voice, image)
2. Classify message type:
   - `order` - Customer placing order
   - `inquiry` - Product/catalog question
   - `payment` - Payment confirmation/receipt
   - `support` - Customer service request
   - `unknown` - Low confidence, flag for review
3. Extract entities:
   - Phone number (from WhatsApp `from` field)
   - Product names (if order)
   - Quantities (if order)
   - Amounts (if payment)

**Output:**
- `message_type`: order | inquiry | payment | support | unknown
- `confidence`: 0-1 score
- `entities`: Extracted data (products, quantities, amounts)
- `requires_review`: Boolean (if confidence < 0.8)

**Database:**
- Write: `message_logs` table (audit trail)
- Write: `daily_logs` table (if requires_review = true)

**Why Second:**
- Routes messages to correct handler
- Brazil pattern: Classification before action
- Nigeria pattern: Flag low confidence for human review

**Coverage:**
- ✅ Max WhatsApp: High automation, minimal database writes
- ✅ Max Truth: Comprehensive logging, review queue
- ✅ All scenarios: Confidence scoring adapts

---

### Workflow 2: Consent Check

**Purpose:** Validate consent before sending messages (Meta requirement)

**Input:**
- `phone` (recipient phone number)
- `channel`: whatsapp | sms
- `purpose`: transactional | marketing
- `message_type`: What we're sending

**Process:**
1. Check `consent` table for active consent
2. Rules:
   - **Transactional**: Implied consent (order confirmations, payment receipts)
   - **Marketing**: Requires explicit consent
3. If no consent and marketing → Don't send, log to review queue
4. If no consent and transactional → Send (implied), create consent record

**Output:**
- `can_send`: Boolean
- `consent_status`: active | missing | revoked
- `reason`: Why can/can't send

**Database:**
- Read: `consent` table
- Write: `consent` table (if creating new record)
- Write: `audit_logs` table (consent check action)

**Why Third:**
- Required before sending any message
- Meta will block account without consent tracking
- Nigeria pattern: Consent from day 1

**Coverage:**
- ✅ Max WhatsApp: Fast consent check, minimal overhead
- ✅ Max Truth: Full consent audit trail
- ✅ All scenarios: Works for both

---

### Workflow 3: Order Processing

**Purpose:** Process customer orders from WhatsApp messages

**Input:**
- Classified message (from Workflow 1)
- `tenant_id` (from Workflow 0)
- Extracted entities (products, quantities)

**Process:**
1. **Parse Order:**
   - Extract products, quantities, prices
   - Handle voice notes (transcribe if needed)
   - Handle images (OCR if needed)
   - Calculate total amount

2. **Create/Update Customer:**
   - Lookup `buyers` table by phone
   - If not found, create new buyer
   - Update `last_message_at`, `conversation_window_expires_at`

3. **Create Order:**
   - Insert into `trades` table
   - Link to buyer, seller (from tenant), products
   - Set status: `pending`
   - Generate order ID

4. **Send Confirmation:**
   - Use Workflow 2 (consent check)
   - Use Workflow 3 (send WhatsApp) - wait, that's this workflow
   - Send order confirmation message via WhatsApp

**Output:**
- `trade_id`: Created order ID
- `status`: pending | confirmed | failed
- `requires_review`: Boolean (if low confidence parse)

**Database:**
- Read: `buyers` table
- Write: `buyers` table (if new customer)
- Write: `trades` table (create order)
- Write: `products` table (if new product detected)
- Write: `daily_logs` table (if requires_review)

**Why Fourth:**
- Core business logic
- India pattern: Order processing is foundation
- Brazil pattern: Handle edge cases (low confidence)

**Coverage:**
- ✅ Max WhatsApp: High automation, minimal database (just orders)
- ✅ Max Truth: Full customer history, product catalog, audit trail
- ✅ All scenarios: Confidence scoring adapts

---

### Workflow 4: Payment Initiation (STK Push)

**Purpose:** Send M-Pesa STK Push to customer for payment

**Input:**
- `trade_id`: Order to pay for
- `phone`: Customer phone number
- `amount`: Payment amount
- `tenant_id`: For M-Pesa credentials

**Process:**
1. **Get Tenant Config:**
   - Use Workflow 0 to get M-Pesa credentials

2. **Generate STK Push:**
   - Call M-Pesa Daraja API
   - Generate password (shortcode + passkey + timestamp, base64)
   - Send STK Push request
   - Get `CheckoutRequestID`

3. **Create Payment Record:**
   - Insert into `payments` table
   - Link to `trade_id`
   - Store `checkout_request_id`
   - Set status: `pending`

4. **Send WhatsApp Notification:**
   - Use Workflow 2 (consent check)
   - Send payment request message

**Output:**
- `checkout_request_id`: M-Pesa checkout ID
- `payment_id`: Created payment record ID
- `status`: pending | sent | failed

**Database:**
- Read: `trades` table (get order details)
- Read: `tenant_config` table (M-Pesa credentials)
- Write: `payments` table (create payment record)
- Write: `message_logs` table (WhatsApp notification)

**Why Fifth:**
- Required for payment flow
- Brazil pattern: Native M-Pesa integration
- Kenya pattern: STK Push is standard

**Coverage:**
- ✅ Max WhatsApp: Send STK Push, minimal tracking
- ✅ Max Truth: Full payment audit trail, retry logic
- ✅ All scenarios: Works for both

---

### Workflow 5: Payment Reconciliation ⭐ **CRITICAL**

**Purpose:** Match M-Pesa callbacks to orders (95%+ match rate)

**Input:**
- M-Pesa callback webhook payload
- `tenant_id` (from webhook query param)

**Process:**
1. **Extract Payment Data:**
   - `mpesa_receipt_number`: Receipt from callback
   - `amount`: Payment amount
   - `phone`: Payer phone number
   - `timestamp`: Payment timestamp

2. **Match to Order:**
   - **Method 1:** Match by `checkout_request_id` (if STK Push)
   - **Method 2:** Match by phone + amount ± tolerance (KSh 10)
   - **Method 3:** Match by phone + timestamp (within 5 minutes)
   - **Method 4:** Flag for manual review (if no match)

3. **Update Records:**
   - Update `payments` table: status = `completed`, `mpesa_ref` = receipt
   - Update `trades` table: status = `paid`, `paid_at` = timestamp
   - Update `buyers` table: `total_spent` += amount

4. **Handle Edge Cases:**
   - Duplicate transactions (check if `mpesa_ref` already exists)
   - Partial payments (if amount < order total)
   - Overpayments (if amount > order total)
   - Unmatched payments (log to `daily_logs` for review)

5. **Send Confirmation:**
   - Use Workflow 2 (consent check)
   - Send payment confirmation message

**Output:**
- `matched`: Boolean
- `trade_id`: Matched order ID (if found)
- `payment_id`: Updated payment record ID
- `requires_review`: Boolean (if unmatched or edge case)

**Database:**
- Read: `payments` table (check for duplicates)
- Read: `trades` table (find matching order)
- Write: `payments` table (update status)
- Write: `trades` table (update order status)
- Write: `buyers` table (update customer stats)
- Write: `daily_logs` table (if unmatched)

**Why Critical:**
- **This is where startups die** - manual matching doesn't scale
- India pattern: Automated reconciliation from day 1
- Nigeria pattern: Multiple matching strategies
- Brazil pattern: Handle edge cases gracefully

**Coverage:**
- ✅ Max WhatsApp: Basic matching, minimal logging
- ✅ Max Truth: Full audit trail, multiple matching strategies, review queue
- ✅ All scenarios: Adapts matching strategy based on confidence

---

### Workflow 6: Send WhatsApp Message

**Purpose:** Send WhatsApp messages (templates or free-form)

**Input:**
- `phone`: Recipient phone number
- `message_type`: order_confirmation | payment_receipt | support | etc.
- `template_name`: WhatsApp template name (if template)
- `parameters`: Template parameters (if template)
- `tenant_id`: For WhatsApp credentials

**Process:**
1. **Get Tenant Config:**
   - Use Workflow 0 to get WhatsApp credentials

2. **Check Consent:**
   - Use Workflow 2 to validate consent

3. **Send Message:**
   - If template: Use Meta WhatsApp Template API
   - If free-form: Use Meta WhatsApp Cloud API (within 24h window)
   - Get message ID from response

4. **Log Message:**
   - Insert into `message_logs` table
   - Track delivery status (if available)

5. **Handle Failure:**
   - If WhatsApp fails, try SMS fallback (Workflow 7)
   - Log fallback reason

**Output:**
- `message_id`: WhatsApp message ID
- `status`: sent | delivered | failed
- `fallback_used`: Boolean (if SMS fallback)

**Database:**
- Read: `tenant_config` table (WhatsApp credentials)
- Read: `consent` table (consent check)
- Write: `message_logs` table (audit trail)

**Why Sixth:**
- Used by all other workflows
- Nigeria pattern: Fallback to SMS
- Brazil pattern: Track delivery status

**Coverage:**
- ✅ Max WhatsApp: High message volume, minimal logging
- ✅ Max Truth: Full message audit trail, delivery tracking
- ✅ All scenarios: Works for both

---

### Workflow 7: SMS Fallback

**Purpose:** Send SMS if WhatsApp fails or unavailable

**Input:**
- `phone`: Recipient phone number
- `message`: SMS content
- `tenant_id`: For SMS provider credentials

**Process:**
1. **Get Tenant Config:**
   - Use Workflow 0 to get SMS provider credentials

2. **Send SMS:**
   - Call SMS provider API (SMSLeopard or AfricasTalking)
   - Get SMS ID from response

3. **Log Message:**
   - Insert into `message_logs` table
   - Mark `fallback_used` = true
   - Record `fallback_reason`

**Output:**
- `sms_id`: SMS provider message ID
- `status`: sent | delivered | failed

**Database:**
- Read: `tenant_config` table (SMS credentials)
- Write: `message_logs` table (audit trail)

**Why Seventh:**
- Fallback strategy
- Nigeria pattern: WhatsApp → SMS fallback
- Kenya pattern: SMS is reliable backup

**Coverage:**
- ✅ Max WhatsApp: Minimal SMS usage
- ✅ Max Truth: Full fallback audit trail
- ✅ All scenarios: Works for both

---

### Workflow 8: eTIMS Submission

**Purpose:** Submit invoices to KRA eTIMS for tax compliance

**Input:**
- `trade_id`: Order to generate invoice for
- `tenant_id`: For eTIMS credentials

**Process:**
1. **Get Order Details:**
   - Query `trades` table
   - Get buyer, seller, products, amounts

2. **Generate Invoice:**
   - Format invoice according to eTIMS schema
   - Include KRA PIN, invoice number, items, tax

3. **Submit to eTIMS:**
   - Call KRA eTIMS OSCU endpoint
   - Get submission receipt

4. **Update Order:**
   - Update `trades` table with invoice number
   - Store eTIMS receipt in `audit_logs`

**Output:**
- `invoice_number`: Generated invoice number
- `etims_receipt`: eTIMS submission receipt
- `status`: submitted | failed

**Database:**
- Read: `trades` table (order details)
- Read: `tenant_config` table (eTIMS credentials)
- Write: `trades` table (update invoice number)
- Write: `audit_logs` table (eTIMS submission)

**Why Eighth:**
- Tax compliance requirement
- Kenya pattern: eTIMS is mandatory
- Brazil pattern: Tax automation

**Coverage:**
- ✅ Max WhatsApp: Submit after payment, minimal tracking
- ✅ Max Truth: Full tax audit trail, retry logic
- ✅ All scenarios: Works for both

---

### Workflow 9: Multi-Rail Payment

**Purpose:** Support multiple payment methods (M-Pesa, PesaLink, Airtel Money)

**Input:**
- `trade_id`: Order to pay for
- `payment_rail`: mpesa | pesalink | airtel_money
- `phone`: Customer phone number
- `amount`: Payment amount

**Process:**
1. **Get Tenant Config:**
   - Use Workflow 0 to get payment rail credentials

2. **Route to Payment Method:**
   - **M-Pesa:** Use Workflow 4 (STK Push)
   - **PesaLink:** Call PesaLink API
   - **Airtel Money:** Call Airtel Money API

3. **Create Payment Record:**
   - Insert into `payments` table
   - Set `payment_method` = selected rail

4. **Handle Callback:**
   - Each payment rail has its own callback
   - Route to Workflow 5 (payment reconciliation)

**Output:**
- `payment_id`: Created payment record ID
- `status`: pending | sent | failed

**Database:**
- Read: `tenant_config` table (payment rail credentials)
- Write: `payments` table (create payment record)

**Why Ninth:**
- Future-proofing
- Brazil pattern: Multi-rail payments
- Kenya pattern: M-Pesa first, others later

**Coverage:**
- ✅ Max WhatsApp: M-Pesa only, minimal complexity
- ✅ Max Truth: Full multi-rail support, comprehensive tracking
- ✅ All scenarios: Start simple, scale up

---

## 🎯 Implementation Strategy

### Phase 1: Foundation (Week 1)

**Must Have:**
1. Workflow 0: Tenant Config Lookup
2. Workflow 1: Message Classification
3. Workflow 2: Consent Check
4. Workflow 5: Payment Reconciliation ⭐ **CRITICAL**

**Why:**
- Without these, nothing works
- Payment reconciliation is non-negotiable
- India pattern: Foundation first

---

### Phase 2: Core Flow (Week 2)

**Must Have:**
1. Workflow 3: Order Processing
2. Workflow 4: Payment Initiation
3. Workflow 6: Send WhatsApp Message

**Why:**
- Core business flow
- Brazil pattern: Order → Payment → Confirmation

---

### Phase 3: Enhancements (Week 3+)

**Nice to Have:**
1. Workflow 7: SMS Fallback
2. Workflow 8: eTIMS Submission
3. Workflow 9: Multi-Rail Payment

**Why:**
- Enhancements, not critical
- Nigeria pattern: Fallback strategies
- Kenya pattern: Tax compliance

---

## 🔧 Missing Capabilities & Solutions

### What I Can't Do Directly:

1. **Execute n8n workflows** → **Solution:** You import workflows, I guide configuration
2. **Test webhooks live** → **Solution:** Use ngrok for local testing, I provide test payloads
3. **Access Meta/Facebook dashboard** → **Solution:** You configure webhooks, I provide exact steps
4. **Test M-Pesa callbacks** → **Solution:** Use Daraja sandbox, I provide test scenarios
5. **Deploy to production** → **Solution:** I provide deployment checklist, you execute

### What I Can Do:

1. ✅ **Create workflow JSON files** → Ready to import
2. ✅ **Provide exact configuration steps** → Step-by-step guides
3. ✅ **Generate test payloads** → For testing workflows
4. ✅ **Write database queries** → For Supabase operations
5. ✅ **Create implementation plans** → This document
6. ✅ **Research best practices** → From other countries
7. ✅ **Identify edge cases** → Payment mismatches, low confidence, etc.

---

## 📊 Coverage Matrix

| Workflow | Max WhatsApp | Max Truth | Edge Cases |
|----------|-------------|-----------|------------|
| 0: Tenant Config | ✅ | ✅ | ✅ |
| 1: Classification | ✅ | ✅ | Low confidence handling |
| 2: Consent | ✅ | ✅ | Missing consent |
| 3: Order Processing | ✅ | ✅ | Voice notes, low confidence |
| 4: Payment Initiation | ✅ | ✅ | STK Push failures |
| 5: Payment Reconciliation | ✅ | ✅ | Unmatched, duplicates |
| 6: Send WhatsApp | ✅ | ✅ | Delivery failures |
| 7: SMS Fallback | ✅ | ✅ | SMS provider failures |
| 8: eTIMS | ✅ | ✅ | Submission failures |
| 9: Multi-Rail | ✅ | ✅ | Rail-specific errors |

---

## 🚀 Next Steps

1. **Review this document** - Confirm workflows match your needs
2. **Import Workflow 0** - Test tenant config lookup
3. **Import Workflow 1** - Test message classification
4. **Import Workflow 5** - Test payment reconciliation ⭐
5. **Configure webhooks** - Meta + M-Pesa
6. **Test end-to-end** - Full flow validation

**Reference:** `docs/core/STRATEGIC_SETUP.md` for setup strategy

---

**Last Updated:** January 9, 2026  
**Status:** Ready for implementation
