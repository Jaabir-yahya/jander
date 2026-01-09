# Business Workflows & User Journeys

**End-to-end business processes, lifecycle stages, and Nairobi-specific adaptations.**

**Reference**: This document cross-references the 7-stage lifecycle (catalog → order → payment → dispatch → delivery → accounting → repeat) with the 5-stage research pattern (Foundation → Containment → Integration → Maturity → Predictive). See [`BUILD_PLAN.md`](./core/BUILD_PLAN.md) for stage-gated execution plan and [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for detailed stage definitions.

---

## The Seven-Stage Lifecycle (Order-to-Delivery Process)

**Mapping to 5-Stage Research Pattern**:

| 7-Stage Lifecycle | Stage 1: Foundation | Stage 2: Containment | Stage 3: Integration | Stage 4: Maturity | Stage 5: Predictive |
|------------------|---------------------|---------------------|---------------------|-------------------|---------------------|
| **1. Catalog Creation** | Manual entry (Google Sheets) | Intent detection for catalog queries | Auto-sync from ERPNext | Template-based broadcasts | AI-generated product recommendations |
| **2. Sharing & Inquiry** | Simple broadcasts | Bot responses for common questions | Automated inquiry routing | A/B tested inquiry templates | Predictive inquiry anticipation |
| **3. Order Capture** | Structured parsing (80%+ accuracy) | Intent detection for orders | Full automation (0% manual) | Optimized order flow | Predictive order suggestions |
| **4. Payment (M-Pesa)** | Basic matching (95%+ auto-match) | Payment link bot responses | Retry logic, cart recovery | Payment analytics | Predictive payment reminders |
| **5. Dispatch & Delivery** | Manual coordination | Order tracking bot responses | Full dispatch automation | Delivery optimization | Predictive delivery alerts |
| **6. Recording & Accounting** | Basic invoice generation | Automated accounting | Full ERPNext integration | Accounting analytics | Predictive accounting insights |
| **7. Repeat Orders & Trust** | Manual reorder prompts | Reorder bot responses | Automated reorder workflows | Retention campaigns | Predictive churn prevention |

**Stages 1-7 are automated fully by Stage 3 (Integration Depth - Weeks 5-8). Stages 4-5 (Maturity & Predictive) optimize and enhance these workflows.**

1. **Catalog Creation** → Traders list products (name, price, images, variants)
2. **Sharing & Inquiry** → Products broadcast to customer WhatsApp groups; buyers ask questions (voice/text/image)
3. **Order Capture** → Order details recorded (manually or via form); stored in system of record
4. **Payment (M-Pesa)** → Customer pays via Till/Paybill; reference code captured; matched to order
5. **Dispatch & Delivery** → Order marked "ready"; rider assigned (boda/Sendy/manual coordination); tracking sent
6. **Recording & Accounting** → Stock deducted; invoice generated (eTIMS-ready); ledger updated
7. **Repeat Orders & Trust** → Post-delivery feedback; reorder quick-replies enabled; credit tracking

---

## Nairobi Adaptations by Stage

| Stage | Generic | Nairobi Reality | Adaptation |
|-------|---------|-----------------|-----------|
| **Catalog** | Photos + SKU + variants | Traders use WhatsApp status, Facebook posts, mental lists | Excel upload → WhatsApp Catalog; voice descriptions (Swahili/Somali) supported |
| **Inquiry** | Quick replies + chatbots | Heavy voice notes; Sheng/Somali; low literacy | Voice memo transcription (Google Speech-to-Text or manual); emoji quick-replies |
| **Capture** | Structured forms | Jotted on notebooks; mixed personal/business chats | Simple text template ("Item, Qty, Name, Tel") or form link; WhatsApp Business webhook captures raw text |
| **Payment** | UPI references; instant reconciliation | M-Pesa Till/Paybill; screenshots as "proof"; high manual matching | Daraja API webhooks auto-match till refs; screenshot fallback for manual verification |
| **Dispatch** | 3PL API integration | Calls to bodaboda riders; coordination via personal chats | Manual rider assignment (v1); Leta/Sendy API (v2) |
| **Accounting** | Auto-ledger sync | Notebooks + rough mental counts; eTIMS non-compliance risk | Auto-invoice generation; simple stock deduct; eTIMS SKU mapping (v2) |
| **Repeat** | CRM + upsell campaigns | Personal relationships; word-of-mouth; WhatsApp groups | Post-delivery rating + reorder button; group broadcasts (templated) |

---

## Order Capture Flows

### Option A: Manual Capture (Weeks 1–2)
1. Customer sends "*Order: 2m red chiffon, for Jane, +254700456789*" to trader WhatsApp
2. Trader (or you) reads it and manually types into Google Sheet or Airtable form
3. n8n checks sheet every 10 mins; if new row, sends auto-reply: "Order confirmed #O001. Pay KSh 500 to Till 123456."

### Option B: Semi-Automated Form (Weeks 2–3)
1. Trader broadcasts link: "Click here to order → [Google Form / Airtable form]"
2. Customer fills: Item name, qty, name, phone, delivery address
3. Form submission → auto-create row in sheet/DB; trigger order confirmation message

### Option C: Structured WhatsApp Flow (Weeks 4+)
1. Customer texts "SHOP" → WhatsApp Flow triggers
2. Flow: Pick item → Pick qty → Confirm phone → Auto-message with order summary & payment link
3. Webhook captures form response → sheet row created

**Nairobi adaptation:** Voice notes are heavy; use speech-to-text (Google Docs voice typing or GCS API) to convert voice → text → auto-populate order.

---

## Missing Pieces in Most Implementations

### 1. Dynamic Pricing
**Problem:** Import costs change weekly (USD rates, supplier price lists). Most traders broadcast new prices manually.

**Mitigation:** Price-list updates imported from shared Google Sheet; old catalog archived.

### 2. Multi-Staff Handling
**Problem:** One phone shared between owner + assistants; no roles/handover protocol.

**Mitigation:** Use WhatsApp Business account (verified); shared inbox with tags (not shared passwords); audit log of who did what (v2).

### 3. Offline Sync
**Problem:** Traders in markets with spotty 4G; orders captured offline, synced later.

**Mitigation:** Offline-first form (e.g., React Native app with local storage); WhatsApp auto-saves drafts; batch sync when online.

### 4. Dispute Handling
**Problem:** Customer claims "order never received"; no formal dispute/return flow.

**Mitigation:** Simple dispute ticket in system; auto-escalation if not resolved in 48 hours; WhatsApp reminder.

### 5. Credit & Partial Payments
**Problem:** Regular customers ask "can I pay half now, half tomorrow?" Informal, trust-based, not tracked.

**Mitigation:** Manual credit limit per trader (v1); 2FA or deposit for first-time buyers; CRM flag for high-risk.

---

## M-Pesa Realities (Nairobi-Specific)

### Till vs Paybill
- **Till (Buy Goods):** Faster approval (~3 days), lower fees (0.5%), instant settlement. Traders prefer.
- **Paybill:** For agencies; more complex. Use till unless business is >KSh 500K/month.

### Reference Matching
- Till transactions send 7-digit receipt code (e.g., "QR3UQR4O")
- Customer reads off phone screen; trader writes in order form or tells you
- Daraja webhook includes this code; you match to order_id
- If webhook fails (network issues), trader can send screenshot

### Statement Reconciliation
- M-Pesa merchant portal allows daily till statement download
- At 6 PM daily, compare to ORDERS.payment_status = "Confirmed"
- Flag unmatched amounts for manual follow-up

---

## Voice & Low-Literacy Handling

### Voice Notes
- Many traders communicate via WhatsApp voice messages, not text
- Use Google Cloud Speech-to-Text API (KSh ~15/month for 100K requests) to transcribe
- Fallback: Manual transcription (you or trained assistant)

#### Voice Note Extraction Workflow
1. **WhatsApp Webhook Receives Voice Message**
   - Extract audio file URL from webhook payload
   - Download audio file (format: .ogg or .amr)

2. **Transcription (Google Cloud Speech-to-Text)**
   - Language code: `sw-KE` (Swahili Kenya) or `en-KE` (English Kenya)
   - Alternative: `so-KE` (Somali Kenya) if Eastleigh traders
   - Enable auto-detect language for Sheng (mixed Swahili/English)
   - Confidence threshold: 0.7 (flag for manual review if lower)

3. **Text Processing (Extract Order Data)**
   - Parse transcribed text for order patterns:
     - Quantity: "senti kumi" (10), "moja" (1), "mbili" (2)
     - Item: "chiffon", "nyuma" (rear fabric), "kitenge"
     - Color: "nyekundu" (red), "bluu" (blue), "nyeusi" (black)
   - Use regex patterns: `/(\d+)\s*(meter|m|metre|senti)/i`
   - Extract customer name/phone if mentioned

4. **Order Creation**
   - If confidence > 0.7: Auto-create order row in Sheets
   - If confidence 0.5-0.7: Flag in DAILY_LOG for manual review
   - If confidence < 0.5: Send WhatsApp to trader: "Voice note unclear. Please type order or send again."

5. **Manual Review Queue (n8n Workflow)**
   - Create row in DAILY_LOG with:
     - event_type: "Voice Note Review"
     - details: Original transcription + audio URL
     - trader_id: Reference
   - Send alert to trader/admin for review
   - Review approved → Create order manually

**Example Transcriptions:**
- "Nataka nyuma chiffon nyekundu senti kumi" → "Order: 10m red chiffon rear fabric"
- "Aah nimtaki moja kitenge bluu" → "Order: 1 blue kitenge"
- "Senti kumi na mbili ya chiffon" → "Order: 12m chiffon"

### Language Support
- **UI:** English (traders on WhatsApp mostly understand English; secondary: Swahili prompts)
- **Broadcasts:** Swahili/Somali templates pre-written; traders fill in product names
- **Example:** "Hi {{name}}, order {{id}} confirmed. Maliza KSh {{amount}} to {{till}}. Shukran!"

### Emoji Quick-Replies
- Instead of "Type YES," use: "✅ Confirm" (tap button, not type)
- WhatsApp Flows use visual buttons; low friction

---

## Boda/Dispatch Realities

### v1 (Manual Coordination)
- Order ready → Trader calls preferred bodaboda rider
- Rider picks up, goes to shop, delivers
- Trader updates WhatsApp status: "On the way → Delivered"
- No API; no tracking; manual scheduling

### v2 (Semi-Automated, Week 6+)
- Keep list of rider contacts + rates per distance
- When order marked "Ready," system suggests closest rider
- Trader approves; SMS/WhatsApp sent to rider with address + customer phone
- Rider marks "Arrived" → customer confirms; "Delivered"

### v3 (Leta API, Week 9+)
- Order confirmed → POST to Leta API with pickup/dropoff
- Leta assigns best rider from network
- Tracking link sent to customer; updated via webhook
- Full audit trail

---

## What Must Exist Before Scaling

Before you scale beyond 5–10 traders:

1. **Single business number** with basic separation of personal vs business chats
2. **Minimal structured order log** (sheet/DB/any backend) updated from WhatsApp
3. **Consistent M‑Pesa reference scheme**, even if matched manually nightly
4. **Clear, simple templates** for common messages (order confirm, payment confirm, dispatch, receipt)
5. **One dispatch path** (even manual) that can be integrated later
6. **Way to export history** for disputes and tax (CSV/Excel/pdf receipts)
7. **Pilot feedback loop**: weekly check-in with traders to identify where they revert to "old way" and why

---

## Stage-by-Stage Workflow Evolution

### Stage 1: Foundation (Weeks 1-2)

**7-Stage Lifecycle Status**: Stages 1-4 partially automated (catalog, inquiry, order capture, payment basic matching)

**Key Workflows**:
- Order Capture: WhatsApp webhook → Order parser → Google Sheets
- Payment Matching: M-Pesa webhook → Basic matching → Google Sheets
- Template Responses: Simple confirmation messages

**Automation Level**: 70% (manual review queue for edge cases)

---

### Stage 2: Containment (Weeks 3-4)

**7-Stage Lifecycle Status**: Stages 1-4 fully automated with bot responses (intent detection, automated responses)

**Key Workflows**:
- Intent Detection: Message classification → Bot response or human handoff
- Order Tracking: "Where is my order?" → Database query → Template response
- Payment Links: "I want to pay" → STK push link → Template response
- Ticket Triage: Support request → Review queue → Trader notification

**Automation Level**: 60-80% containment (60-80% of queries resolved by bot)

---

### Stage 3: Integration (Weeks 5-8)

**7-Stage Lifecycle Status**: **ALL 7 stages fully automated** (catalog → order → payment → dispatch → delivery → accounting → repeat)

**Key Workflows**:
- Post-Purchase Sequences: Order → Payment → Dispatch → Delivery → Review (automated sequence)
- Cart Recovery: Abandoned orders → Reminder sequence (30-36% recovery rate)
- Payment Retry Logic: STK push → Retry → Escalate (reduces manual follow-up by 70%)
- Returns Initiation: Return request → Trader approval → Refund processing

**Automation Level**: 95%+ (no manual data entry required)

---

### Stage 4: Maturity (Weeks 9-12)

**7-Stage Lifecycle Status**: ALL 7 stages optimized with analytics and A/B testing

**Key Workflows**:
- Template A/B Testing: Test template variations → Optimize conversion
- Send Time Optimization: Discover optimal send times (Kenya-specific, may differ from India/Brazil)
- Workflow Optimization: Reduce steps in payment flow, improve intent prompts
- ROI Quantification: Financial ROI calculation (target: 18:1+ ratio)

**Automation Level**: 95%+ with data-driven optimizations

---

### Stage 5: Predictive (Weeks 13+)

**7-Stage Lifecycle Status**: ALL 7 stages enhanced with predictive and proactive features

**Key Workflows**:
- Proactive Notifications: Delivery delay alerts, return window reminders
- Retention Campaigns: Reorder nudges, churn prediction, win-back sequences
- AI-Assisted Routing: Embeddings-based intent classification, context summarization
- Revenue Workflows: Purchase → Recommendations, return → re-engagement

**Automation Level**: 95%+ with AI-assisted optimization

---

## References

- **Master Blueprint**: [`BUILD_PLAN.md`](./core/BUILD_PLAN.md) - Stage-gated execution plan
- **Stage Definitions**: [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) - Detailed stage definitions and research citations
- **Communication Rails**: [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) - API contracts and data flows
- **Analytics Schema**: [`ANALYTICS_SCHEMA.md`](./ANALYTICS_SCHEMA.md) - Metrics definitions and KPI tracking

---

**Last Updated:** 2026-01-09  
**Status**: Stage 1 in progress (Days 1-5), Workflows mapped to 5-stage pattern  
**Next Review**: End of Week 1 (Stage 1 gate review)

