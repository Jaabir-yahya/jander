# Quick Reference Guide

**One-page cheat sheet for building WhatsApp-as-a-Service in Nairobi.**

**For detailed technical integration guides, see:** [`WhatsApp_Commerce_Technical_KB.md`](../core/WhatsApp_Commerce_Technical_KB.md) ⭐

---

## 🧠 Mental Model

**Three Layers:**
```
Channels (WhatsApp/SMS) → n8n (Orchestration) → ERPNext (Truth)
```

**Key Principle:**
- Channels are replaceable
- Orchestration adapts
- Records must never break

---

## ✅ What TO Build

**Week 1:**
1. ✅ Database schema (Supabase - 7 core + 6 WaaS tables)
2. ✅ WhatsApp integration (SMSLeopard/Meta abstraction)
3. ✅ M-Pesa STK Push + B2C payouts
4. ✅ Conversation window tracking (24h management)

**Week 2-3:**
5. ✅ SMS fallback integration
6. ✅ n8n workflows (first 7: classify, consent, send, fallback, log, reconcile, confirm)
7. ✅ Consent tracking (opt-in/opt-out)

**Week 5-8:**
8. ✅ ERPNext integration (DocTypes, REST API)

---

## ❌ What NOT to Build (Save 6-12 Months)

1. ❌ Custom WhatsApp bot (full AI conversations)
2. ❌ Custom ERP from scratch
3. ❌ SaaS-only stack (Zapier, Airtable, Twilio)
4. ❌ Single business assumptions
5. ❌ WhatsApp-only (no SMS fallback)
6. ❌ No consent tracking
7. ❌ No audit trail
8. ❌ Hardcoded business logic in n8n

**See [`DO_NOT_BUILD.md`](./DO_NOT_BUILD.md) for full list.**

---

## 📋 First 7 n8n Workflows (Build Order)

1. `classify_message` - Foundation (needed by all)
2. `check_consent` - Protection (prevent violations)
3. `send_whatsapp` - Core messaging
4. `send_sms_fallback` - Reliability
5. `log_message` - Audit trail
6. `reconcile_payment` - Trust
7. `send_payment_confirmation` - Transparency

**See [`FIRST_7_WORKFLOWS.md`](./FIRST_7_WORKFLOWS.md) for details.**

---

## 🔧 Integration Requirements

**MUST-HAVE (Day 1):**

| Integration | Must-Have | Cost/Month |
|-------------|-----------|------------|
| **WhatsApp** | Templates, webhooks, sessions, delivery receipts | KSh 0-2,000 |
| **SMS** | Send, webhooks, bulk, delivery reports | KSh 500-5,000 |
| **n8n** | Webhooks, HTTP, JSON, conditionals, loops, error handling | KSh 5,000 |
| **ERPNext** | DocTypes, REST API, search, unique constraints, audit trail | KSh 3,000 |
| **M-Pesa** | STK push, webhooks, reconciliation | KSh 0 (Safaricom fee) |

**See [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md) for full matrix.**

---

## 🗄️ Database Schema (Core Tables)

**Trade Facilitator (7 tables):**
- `trades` - Central trade entity
- `buyers` - Buyer profiles
- `sellers` - Seller profiles
- `products` - Product catalog
- `conversations` - Conversation windows
- `payments` - Payment transactions
- `payouts` - Seller payouts

**WaaS Core (6 tables):**
- `consent` - Opt-in/opt-out tracking
- `message_logs` - Message audit trail
- `audit_logs` - Business actions audit
- `agents` - Human operators
- `merchant_outlets` - Physical locations
- `daily_logs` - Disputes & review queue

**Migration Files:**
- `001_create_trade_facilitator_schema.sql`
- `002_add_waas_core_tables.sql`

---

## 🔑 Key Principles

**Phone Number = Primary Key**
- Not email. Not username.
- Format: `+2547XXXXXXXX`
- Unique, indexed, immutable

**Consent Tracking**
- Transactional = implied consent
- Marketing = explicit consent
- Track: source, timestamp, channel, purpose

**Message Taxonomy**
- OTP/Auth → SMS (no fallback)
- Payment/Order → WhatsApp → SMS (fallback)
- Support → WhatsApp (no fallback)
- Promotions → WhatsApp (opt-in only)

**Fallback Strategy**
1. Send WhatsApp
2. Wait delivery receipt (60s timeout)
3. If failed → Send SMS
4. Log both attempts

**Payment Reconciliation**
- Match by phone + amount (±50 KSh tolerance)
- If one match → Auto-confirm
- If multiple/no match → Manual review

---

## 📊 Cost Per Trade

**Assumptions:**
- Average order: KSh 2,000
- Conversations per trade: 2.5
- WhatsApp cost: KSh 0.75/conversation
- SMS fallback: 20% of messages

**Cost Breakdown:**
- WhatsApp: 2.5 × KSh 0.75 = KSh 1.88
- SMS fallback: 0.5 × KSh 1.00 = KSh 0.50
- Platform: KSh 0.50
- **Total: KSh 2.88 per trade**

**Revenue:**
- Transaction fee: KSh 50-100 (2.5-5% of KSh 2,000)
- **Net margin: KSh 47.12-97.12 per trade**

---

## 🧪 Testing Checklist

**Before MVP Launch:**

- [ ] WhatsApp: Send template, receive webhook, parse phone, delivery receipt
- [ ] SMS: Send, receive webhook, parse status, bulk send
- [ ] n8n: Webhook receives, creates order, sends WhatsApp, falls back to SMS
- [ ] ERPNext: Create customer, create order, update status, query by phone
- [ ] M-Pesa: STK push, webhook, reconcile payment, update order
- [ ] E2E: Full trade flow (message → order → payment → confirmation)

**See [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md) for full checklist.**

---

## 📚 Documentation Map

**Architecture:**
- [`WAAS_ARCHITECTURE.md`](./architecture/WAAS_ARCHITECTURE.md) - Three-layer architecture
- [`TRADE_FACILITATOR_ARCHITECTURE.md`](./architecture/TRADE_FACILITATOR_ARCHITECTURE.md) - Hub-and-spoke model
- [`ARCHITECTURE.md`](./core/ARCHITECTURE.md) - Technical architecture

**Execution:**
- [`BUILD_PLAN.md`](./core/BUILD_PLAN.md) - Stage-gated plan (Weeks 1-12)
- [`WEEK1_EXECUTION_PLAN.md`](./WEEK1_EXECUTION_PLAN.md) - Week 1 tasks

**Integration:**
- [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md) - Capability matrix
- [`FIRST_7_WORKFLOWS.md`](./FIRST_7_WORKFLOWS.md) - n8n workflow guide
- [`DO_NOT_BUILD.md`](./DO_NOT_BUILD.md) - Anti-patterns guide

---

## 🚀 Quick Start Commands

```bash
# 1. Configure environment
cd apps/whatsapp-business
cp .sample.env .env
# Edit .env with credentials

# 2. Run database migration (Supabase SQL Editor)
# Copy: apps/supabase/migrations/001_create_trade_facilitator_schema.sql
# Copy: apps/supabase/migrations/002_add_waas_core_tables.sql
# Execute in Supabase SQL Editor

# 3. Install dependencies
npm install

# 4. Start server
npm start

# 5. Test webhook
curl -X GET "http://localhost:3000/webhook?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=test123"

# 6. Run test suite
node scripts/test-trade-facilitator.js
```

---

## 💡 Mental Model Reminder

**If something feels hard, you're probably putting logic in the wrong layer:**

- **ERPNext** = Business truth (customer, order, payment, consent)
- **n8n** = Flow logic (routing, retry, fallback, timing)
- **WhatsApp/SMS** = User interface (replaceable)

**If it feels clever, it's probably fragile.**
**If it feels boring, it will scale.**

---

**Last Updated**: 2026-01-09  
**Status**: Quick reference complete, all key principles documented

