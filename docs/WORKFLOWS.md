# Business Workflows & User Journeys

**End-to-end business processes, lifecycle stages, and Nairobi-specific adaptations.**

---

## The Seven-Stage Lifecycle

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

**Last Updated:** Update this document as workflows evolve during build.

