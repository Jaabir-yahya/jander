# **NAIROBI SUPER SUITE: ORCHESTRATION MASTER DOCUMENT** (SUPERCHARGED)

**Final Product Definition + Complete Orchestration Network + Context Integration**  
**Date:** January 9, 2026 | Status: Production-Ready Blueprint

***

## **THE CORE INSIGHT**
Your magic isn't in features—it's in the **orchestration network** that turns Nairobi's dominant commerce channels (Instagram→WhatsApp→M-Pesa) into a single automated revenue engine. This document maps every business outcome to its orchestration recipe, rooted in real Nairobi SME patterns and global WhatsApp commerce standards. [1][2]

***

## **1. THE ORCHESTRATION LAYER MAP**

### **1.1 The Channel Orchestrators (Nairobi-Specific Adaptation)**

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    NAIROBI SUPER SUITE ORCHESTRATION                     │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │  INSTAGRAM       │  │  WHATSAPP        │  │  M-PESA          │      │
│  │  ORCHESTRATOR    │  │  ORCHESTRATOR    │  │  ORCHESTRATOR    │      │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────────┤      │
│  │ • Reels comment  │  │ • Text parse     │  │ • STK Push API   │      │
│  │   intake         │  │ • Voice parse    │  │ • C2B Webhook    │      │
│  │ • Lead routing   │  │   (Sheng/Somali)│  │ • Exact match    │      │
│  │ • DM auto-reply  │  │ • Order capture  │  │ • Fuzzy match    │      │
│  │ • Influencer tag │  │ • Catalog serve  │  │   (±15 KSh)      │      │
│  │ • ROAS tracking  │  │ • Flows forms    │  │ • Signature      │      │
│  │ • Story insights │  │ • Receipt send   │  │   verification   │      │
│  │ • Trending Reels │  │ • Broadcast msgs │  │ • Audit trail    │      │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘      │
│           │                     │                     │                 │
│           └─────────────────────┼─────────────────────┘                 │
│                                 │                                       │
│           ┌─────────────────────▼─────────────────────┐                │
│           │    CENTRAL STATE MACHINE (Supabase)       │                │
│           │  ├─ leads (Instagram source)              │                │
│           │  ├─ orders (WhatsApp captured)            │                │
│           │  ├─ payments (M-Pesa reconciled)          │                │
│           │  ├─ inventory (realtime stock)            │                │
│           │  ├─ deliveries (Glovo/Sendy tracking)     │                │
│           │  ├─ customers (RFM segmentation)          │                │
│           │  ├─ conversations (full history)            │                │
│           │  ├─ review_queue (manual interventions)    │                │
│           │  └─ analytics (ROI, attribution)          │                │
│           └─────────────────────────────────────────┘                │
│                                 │                                       │
│           ┌─────────────────────▼─────────────────────┐                │
│           │   n8n WORKFLOW ORCHESTRATION ENGINE       │                │
│           │  ├─ Webhook Receivers (3 endpoints)       │                │
│           │  ├─ Workflow Library (14 core workflows)  │                │
│           │  ├─ Error Handlers (retry + DLQ)          │                │
│           │  ├─ Circuit Breakers (API resilience)     │                │
│           │  └─ Tenant Context Injectors              │                │
│           └─────────────────────────────────────────┘                │
│                                 │                                       │
│           ┌─────────────────────▼─────────────────────┐                │
│           │    CUSTOMER DASHBOARD (Realtime)          │                │
│           │  ├─ ROAS per Reel/Campaign                │                │
│           │  ├─ Lead→Order→Paid conversion funnel    │                │
│           │  ├─ Inventory alerts                      │                │
│           │  ├─ Delivery tracking                     │                │
│           │  ├─ Customer VIP segmentation             │                │
│           │  └─ Weekly revenue forecast               │                │
│           └─────────────────────────────────────────┘                │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### **1.2 The Orchestration Network Principles**

```
1. EVENTS OVER POLLING
   ✅ Instagram webhook → instant trigger
   ✅ WhatsApp webhook → zero latency
   ✅ M-Pesa webhook → real-time reconciliation
   ❌ No "check every 5 minutes" (wastes API quota)

2. STATE IS KING
   Every meaningful event = database record
   Example flow:
   Instagram comment → leads table (new)
   ↓ (WA message sent)
   → leads table (contacted)
   ↓ (WhatsApp reply)
   → orders table (created)
   ↓ (M-Pesa payment)
   → orders table (paid)

3. FAILURE IS EXPECTED
   Design for:
   • Webhook retries (3x with exponential backoff)
   • API fallbacks (WhatsApp → SMS)
   • Dead letter queue (manual review)
   • Circuit breakers (prevent cascade failure)

4. TENANT CONTEXT FLOWS EVERYWHERE
   Every workflow executes with:
   • tenant_id injected from webhook path
   • RLS policies enforce isolation
   • Credentials pulled from tenant_config
   • Audit logged per tenant

5. DETERMINISTIC IDEMPOTENCY
   Every API webhook is idempotent:
   • M-Pesa: MpesaReceiptNumber unique
   • WhatsApp: message_id unique
   • Instagram: comment_id unique
   Process 100x = same result as process 1x
```

***

## **2. COMPLETE USE CASE → ORCHESTRATION MAPPING**

### **2.1 Revenue Capture Flow (The Money Pipeline)**

**Business Need**: "A customer sees a Reel, wants to buy, pays instantly"  
**Success Metric**: < 5 minutes from comment to payment confirmation

```
┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: INSTAGRAM LEAD CAPTURE                                          │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    POST /webhook/meta/:tenant_id                              │
│ Event:      {type: "comment", text: "YES", author: "@username"}        │
│                                                                         │
│ Workflow:   IG_LEAD_CAPTURE                                            │
│ Logic:      • Filter keywords: ["YES", "DM", "Price", "Stock?"]       │
│             • Extract @username from comment                           │
│             • Lookup phone from Instagram bio/followers                │
│             • Enrich with location (from comment geo)                  │
│             • Tag with Reel ID + campaign ID                          │
│                                                                         │
│ Database:   INSERT INTO leads (                                        │
│               tenant_id, instagram_handle, phone,                      │
│               reel_id, campaign_id, source, status, created_at         │
│             ) VALUES (...)                                             │
│             UPDATE reels SET comment_count++ WHERE id=$1              │
│                                                                         │
│ Success:    leads.status = 'new'                                       │
│ Failure:    → DLQ + admin alert                                       │
│ Duration:   < 500ms                                                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 2: WHATSAPP INITIAL CONTACT                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    DB trigger: leads.status → 'new'                           │
│                                                                         │
│ Workflow:   WA_INITIAL_CONTACT                                         │
│ Logic:      • Normalize phone to 254XXXXXXXXX                          │
│             • Verify WhatsApp registration (optional check)            │
│             • Fetch tenant's product catalog                           │
│             • Format catalog message (text or WhatsApp catalog)        │
│             • Send via Meta API                                        │
│             • Store message_id for idempotency                         │
│                                                                         │
│ API Call:   POST https://graph.instagram.com/v18.0/me/messages        │
│             {                                                          │
│               "messaging_product": "whatsapp",                        │
│               "to": "{{phone}}",                                       │
│               "type": "template" | "catalog" | "text",               │
│               "template": {...} | "catalog_id": "..."                │
│             }                                                          │
│                                                                         │
│ Database:   UPDATE leads SET status='contacted', wasted_at=NOW()      │
│             INSERT INTO messages (direction, source, content, status) │
│                                                                         │
│ Success:    leads.status = 'contacted'                                 │
│ Failure:    SMS fallback or DLQ                                        │
│ Duration:   < 2 seconds                                                │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 3: WHATSAPP ORDER PARSING (TEXT/VOICE)                             │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    POST /webhook/meta/:tenant_id (message incoming)           │
│ Event:      {type: "message", from: "254700123456",                   │
│              message: {text: "500 KSh for 2 units"} OR                │
│                       {audio: {...}, media_type: "audio/ogg"}}       │
│                                                                         │
│ Workflow:   WA_ORDER_PARSER (Smart Multi-Path)                        │
│                                                                         │
│ Path A: TEXT ORDER                                                     │
│ • Regex extraction:                                                    │
│   - Amount: /(\d+)\s*(KSh|sh|shilling)/i                             │
│   - Quantity: /(\d+)\s*(units?|items?|pairs?)/i                      │
│   - Product: Extract from catalog context                             │
│ • Parse patterns:                                                      │
│   - "500 for 2 units"                                                 │
│   - "2 × KSh 500"                                                     │
│   - "500 shillings"                                                   │
│   - Voice: "nimtaka kilo mbili" (Swahili)                            │
│                                                                         │
│ Path B: VOICE ORDER (Sheng/Somali Support)                           │
│ • Google Cloud Speech-to-Text                                         │
│ • Language detection                                                   │
│ • Sheng patterns: "pesa iko?", "stock ni sawa?", "delivery eko?"     │
│ • Parse transcript → extract amount/quantity                          │
│ • Confidence scoring (flag if < 80%)                                  │
│                                                                         │
│ Path C: STRUCTURED REPLY (WhatsApp Flows)                            │
│ • Button click: "Order" → pre-filled form                            │
│ • Extract from JSON form submission                                   │
│                                                                         │
│ Validation:                                                            │
│ • Check inventory: SELECT quantity FROM inventory WHERE ...           │
│ • Fail fast if OOS (offer alternatives)                              │
│ • Validate phone is customer (DLQ if mismatch)                       │
│                                                                         │
│ Database:   INSERT INTO orders (                                      │
│               tenant_id, customer_phone, product, quantity,           │
│               amount, status, created_at, conversation_history       │
│             )                                                          │
│                                                                         │
│ Success:    orders.status = 'created' → Triggers MP_STK_TRIGGER      │
│ Failure:    "I didn't understand, try again" or queue for review     │
│ Duration:   < 3 seconds (text), < 5 seconds (voice)                  │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 4: M-PESA PAYMENT REQUEST (STK PUSH)                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    DB trigger: orders.status → 'created'                     │
│ OR Manual:  Customer selects payment method                            │
│                                                                         │
│ Workflow:   MP_STK_TRIGGER                                            │
│ Logic:      • Format phone: 254700123456                              │
│             • Generate unique checkout_request_id                     │
│             • Call Daraja STK Push API                               │
│             • Store reference ID for reconciliation                   │
│             • Set timeout (STK valid for 30 seconds)                  │
│                                                                         │
│ API Call:   POST https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest
│             {                                                          │
│               "BusinessShortCode": "174379",                         │
│               "Password": "{{base64(sc+timestamp+pwd)}}",            │
│               "Timestamp": "20260109093000",                         │
│               "TransactionType": "CustomerPayBillOnline",           │
│               "Amount": "{{order.amount}}",                          │
│               "PartyA": "254700123456",                             │
│               "PartyB": "174379",                                    │
│               "PhoneNumber": "254700123456",                         │
│               "CallBackURL": "https://yourapp.com/webhook/mpesa",  │
│               "AccountReference": "{{checkout_request_id}}"         │
│             }                                                          │
│                                                                         │
│ Database:   UPDATE orders SET                                         │
│               checkout_request_id = $1,                               │
│               stk_initiated_at = NOW(),                              │
│               status = 'payment_pending'                              │
│                                                                         │
│ Customer:   "Send payment push received on your phone"               │
│             (Appears as popup on customer's M-Pesa menu)             │
│                                                                         │
│ Success:    orders.status = 'payment_pending'                         │
│ Failure:    DLQ + manual review                                       │
│ Duration:   < 2 seconds (STK appears instantly)                       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 5: PAYMENT RECONCILIATION (THE MOST CRITICAL WORKFLOW)             │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    POST /webhook/mpesa/:tenant_id                            │
│ Event:      Daraja C2B webhook with payment confirmation              │
│             {                                                          │
│               "MpesaReceiptNumber": "NLJ7FF5ZX0",                    │
│               "Amount": "500",                                        │
│               "PhoneNumber": "254700123456",                         │
│               "TransactionDate": "20260109093045"                    │
│             }                                                          │
│                                                                         │
│ Workflow:   MP_RECONCILER (THE MAGIC HAPPENS HERE)                   │
│                                                                         │
│ Step 1: Verify Signature                                              │
│         • Reconstruct M-Pesa signature                               │
│         • HMAC-SHA256(payload + secret)                              │
│         • Verify matches webhook header                              │
│         → If mismatch: REJECT (potential replay attack)              │
│                                                                         │
│ Step 2: Check Idempotency                                            │
│         • Query: SELECT * FROM payments                              │
│           WHERE mpesa_receipt_number = $1                            │
│         → If exists: Return success (already processed)              │
│         → Prevents duplicate charges                                  │
│                                                                         │
│ Step 3: Find Matching Order (EXACT MATCH FIRST)                      │
│         SELECT id, amount FROM orders WHERE                          │
│           checkout_request_id = $mpesa_account_reference             │
│         → If found with amount = $mpesa_amount:                      │
│           confidence = 1.0 (100%)                                    │
│           AUTO-RECONCILE (skip fuzzy)                                │
│                                                                         │
│ Step 4: Fuzzy Match (If No Exact Match)                              │
│         • Tolerance: ±15 KSh (M-Pesa fees + float)                  │
│         • Query: SELECT id, amount FROM orders WHERE                 │
│           phone = $mpesa_phone AND                                   │
│           amount BETWEEN ($mpesa_amount-15) AND ($mpesa_amount+15)  │
│           AND status = 'payment_pending' AND                         │
│           created_at > NOW() - INTERVAL '24 hours'                  │
│           ORDER BY ABS(amount - $mpesa_amount) ASC LIMIT 1          │
│                                                                         │
│         • Calculate confidence:                                       │
│           confidence = 1 - (abs_diff / 30)                          │
│           If confidence > 0.9: AUTO-RECONCILE                        │
│           If confidence < 0.9: QUEUE FOR REVIEW                      │
│                                                                         │
│ Step 5: Update Order (If High Confidence)                            │
│         UPDATE orders SET                                            │
│           status = 'paid',                                           │
│           paid_at = NOW(),                                           │
│           mpesa_receipt = $receipt_number                            │
│         WHERE id = $matched_order_id                                 │
│                                                                         │
│ Step 6: Create Payment Record                                         │
│         INSERT INTO payments (                                        │
│           tenant_id, order_id, amount,                               │
│           mpesa_transaction_id, match_type, confidence,              │
│           auto_matched, status, created_at                           │
│         ) VALUES (...)                                               │
│                                                                         │
│ Step 7: Queue Manual Review (If Low Confidence)                      │
│         INSERT INTO review_queue (                                    │
│           tenant_id, item_type, item_id,                             │
│           reason, data, priority                                      │
│         ) VALUES (                                                    │
│           $tenant_id, 'payment_match',                               │
│           $receipt_number,                                           │
│           'Fuzzy match confidence ' || $confidence,                  │
│           jsonb {...},                                               │
│           'high'                                                      │
│         )                                                             │
│         SEND ALERT: Owner WhatsApp                                    │
│         "Manual check needed: KSh 525 vs order KSh 500"             │
│                                                                         │
│ Database:   All atomic - use Supabase functions for ACID             │
│             transactions                                              │
│                                                                         │
│ Success:    orders.status = 'paid'                                    │
│             → Triggers: DEL_ETA_ESTIMATOR, KRA_INVOICE_CREATOR      │
│ Failure:    → DLQ with alert                                         │
│ Duration:   < 1 second                                                │
│                                                                         │
│ SUCCESS RATE TARGET: 98.5% auto-reconciliation                        │
└─────────────────────────────────────────────────────────────────────────┘
```

### **2.2 Inventory Intelligence Flow (Stock Management)**

**Business Need**: "Never oversell, alert me when running low"  
**Nairobi Reality**: 30% of SMEs say "out of stock" manually → lost sales [3]

```
┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: STOCK LEVEL MONITORING                                          │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Cron: Every 30 minutes                                     │
│ OR:         Realtime: When inventory.quantity decremented              │
│                                                                         │
│ Workflow:   INV_STOCK_CHECK                                           │
│ Logic:      • Query: SELECT * FROM inventory WHERE                    │
│               quantity <= min_threshold AND                            │
│               last_alert_sent < NOW() - INTERVAL '6 hours'            │
│             • For each low-stock item:                                │
│               - Calculate days until stockout                         │
│               - Identify bestsellers (needs faster restock)           │
│               - Flag seasonal products                                │
│                                                                         │
│ Database:   UPDATE inventory SET                                       │
│               alert_sent_at = NOW(),                                   │
│               alert_count = alert_count + 1                           │
│             WHERE id = $product_id                                    │
│                                                                         │
│ Success:    Triggers WA_BROADCAST_ALERT                              │
│ Duration:   < 2 seconds per 100 products                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 2: OWNER NOTIFICATION                                              │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    inventory.alert_sent_at updated                            │
│                                                                         │
│ Workflow:   WA_BROADCAST_ALERT                                        │
│ Logic:      • Format message:                                          │
│               "⚠️ Stock Alert                                          │
│                🏀 Pair Size 9: 3 pairs left                           │
│                📦 Est. stockout: 2 days                               │
│                👉 Reorder now?"                                       │
│             • Send to owner WhatsApp                                   │
│             • Optional: Slack + SMS to backup                         │
│                                                                         │
│ Database:   INSERT INTO alerts (...) for audit                        │
│                                                                         │
│ Success:    Notification delivered                                     │
│ Failure:    DLQ + retry next run                                      │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 3: CUSTOMER OUT-OF-STOCK HANDLING                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    WA_ORDER_PARSER detects OOS item                          │
│ Event:      Customer: "I want 5 pairs size 9"                         │
│             System: *checks inventory* → 0 in stock                    │
│                                                                         │
│ Workflow:   WA_OOS_HANDLER                                            │
│ Logic:      • Check if pre-orders allowed                             │
│             • Suggest alternatives:                                   │
│               - Same product, different size/color                    │
│               - Similar products (via recommendation engine)          │
│             • Option 1: Notify when back in stock                     │
│             • Option 2: Pre-order with deposit (if enabled)           │
│                                                                         │
│ Database:   INSERT INTO waitlist (customer, product, priority)        │
│             If pre-order: Create "pre_order_payment" status order    │
│                                                                         │
│ Success:    Waitlist created OR alternative purchased                 │
│ Future:     When back in stock → WA_NOTIFICATION ("Your item back!")  │
└─────────────────────────────────────────────────────────────────────────┘
```

### **2.3 Delivery & Trust Flow (Logistics Integration)**

**Business Need**: "Customers know exactly when to expect delivery"  
**Nairobi Context**: Glovo, Sendy, Gopuff are delivery partners [3]

```
┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: DELIVERY ETA ESTIMATION                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    DB trigger: orders.status → 'paid'                        │
│                                                                         │
│ Workflow:   DEL_ETA_ESTIMATOR                                         │
│ Logic:      • Extract delivery location (from customer phone)         │
│             • Determine Nairobi zone (Westlands, Southlands, CBD, etc)|
│             • Query historical                                   │
│               SELECT AVG(delivered_at - created_at) as avg_hours      │
│               FROM deliveries WHERE zone = $customer_zone             │
│               AND product_category = $product_category               │
│             • Add buffer: avg_hours × 1.2 (20% buffer for delays)   │
│             • Calculate final ETA                                     │
│                                                                         │
│ Delivery Partners:                                                     │
│ • If order value < KSh 1000: Self-delivery or USSD reminder          │
│ • If order value KSh 1000-5000: Glovo API integration               │
│ • If order value > KSh 5000: Sendy API (cargo tracking)             │
│                                                                         │
│ Database:   UPDATE orders SET                                         │
│               delivery_zone = $zone,                                   │
│               estimated_delivery_at = NOW() + $eta_interval,         │
│               delivery_method = $method,                              │
│               delivery_partner_id = $partner_id                      │
│                                                                         │
│ Success:    orders.delivery_eta set                                    │
│ Duration:   < 1 second                                                │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 2: DELIVERY ETA NOTIFICATION                                       │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    orders.estimated_delivery_at set                          │
│                                                                         │
│ Workflow:   WA_ETA_NOTIFIER                                           │
│ Logic:      • Format friendly message:                                │
│               "📦 Order on the way!                                   │
│                ⏰ Expected: Today, 3-5 PM                            │
│                📍 Nairobi - CBD Zone                                 │
│                👤 Driver: John | 📞 0712345678                       │
│                🔗 Track: [clickable link]"                           │
│             • If SMS channel: Shorten to fit SMS length               │
│                                                                         │
│ Database:   INSERT INTO notifications (...)                           │
│                                                                         │
│ Success:    Message delivered                                         │
│ Failure:    Fallback to SMS (Africa's Talking)                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 3: DELIVERY DELAY HANDLING                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Manual: Owner marks "delayed"                              │
│ OR Auto:    Realtime check: Current time > ETA + 30 mins              │
│                                                                         │
│ Workflow:   WA_DELAY_HANDLER                                          │
│ Logic:      • If manual delay:                                         │
│               UPDATE orders SET delivery_delayed = true               │
│             • If auto-detected:                                       │
│               Query delivery partner API for live status              │
│               If stuck/stalled: Flag                                  │
│             • Format message:                                         │
│               "⏳ Slight delay on your order                          │
│                Expected now: 4-6 PM (was 3-5 PM)                     │
│                Reason: Traffic                                        │
│                🎁 Apology: 10% discount on next order"               │
│             • Log in audit trail                                      │
│                                                                         │
│ Database:   UPDATE orders SET delay_reason, new_eta                   │
│             INSERT INTO vouchers (customer, discount)                 │
│                                                                         │
│ Success:    Customer informed, goodwill maintained                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 4: DELIVERY COMPLETION & RECEIPT                                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Delivery partner API webhook: "delivery_completed"         │
│ OR Manual:  Owner marks "delivered"                                    │
│                                                                         │
│ Workflow:   DEL_COMPLETION_HANDLER                                    │
│ Logic:      • Update order status                                     │
│             • Send receipt + thank you message                        │
│             • Request review/rating                                   │
│             • Trigger reorder reminder (set for 7 days)              │
│                                                                         │
│ Database:   UPDATE orders SET                                         │
│               status = 'delivered',                                    │
│               delivered_at = NOW()                                    │
│                                                                         │
│ Success:    Complete order lifecycle                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### **2.4 Analytics & Insight Flow (The Intelligence Engine)**

**Business Need**: "Which Reels actually make money? Show me ROAS."  
**Nairobi Advantage**: Local agencies don't have this—you'll dominate. [1][4]

```
┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: DAILY ANALYTICS SNAPSHOT                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Cron: Daily 2 AM (off-peak)                               │
│                                                                         │
│ Workflow:   ANALYTICS_DAILY                                           │
│ Logic:      • Aggregate yesterday's                               │
│               - Leads created: COUNT(*) FROM leads WHERE created_at...│
│              
│ Workflow:   ANALYTICS_DAILY                                           │
│ Logic:      • Aggregate yesterday's data:                            │
│               - Leads created: COUNT(*) FROM leads WHERE created_at...│
│               - Orders created: COUNT(*) FROM orders WHERE ...        │
│               - Revenue (paid): SUM(amount) FROM payments where...    │
│               - Conversion rate: orders / leads × 100                 │
│               - ROAS per campaign:                                    │
│                 SELECT campaign_id,                                   │
│                        SUM(paid.amount) / SUM(ad_spend) as ROAS      │
│                 FROM payments p                                       │
│                 JOIN orders o ON p.order_id = o.id                   │
│                 JOIN leads l ON o.lead_id = l.id                     │
│                 WHERE campaign_id = ...                              │
│               - ROAS per Reel:                                        │
│                 Same logic, group by reel_id                         │
│                                                                         │
│ Database:   CREATE TABLE analytics_daily (                            │
│               date, tenant_id, leads_count, orders_count,            │
│               revenue, conversion_rate, roas_avg                     │
│             );                                                         │
│                                                                         │
│ Success:    Metrics calculated and stored                             │
│ Duration:   < 30 seconds for typical SME                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 2: REALTIME DASHBOARD UPDATES                                      │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Supabase Realtime: Any table change                       │
│                                                                         │
│ Workflow:   ANALYTICS_REALTIME (Browser → Dashboard)                 │
│ Logic:      • WebSocket connection to Supabase Realtime               │
│             • Listen to: leads, orders, payments changes              │
│             • On change:                                              │
│               - Recalculate running totals                            │
│               - Push update to browser                                │
│               - Update cards: Today's leads, Today's revenue, etc     │
│                                                                         │
│ Example Client Code:                                                   │
│ ```javascript                                                          │
│ const supabase = createClient(url, key);                              │
│                                                                         │
│ supabase                                                               │
│   .channel('analytics')                                               │
│   .on('postgres_changes',                                             │
│     { event: 'INSERT', schema: 'public', table: 'orders' },         │
│     (payload) => {                                                    │
│       updateDashboardCard('today_revenue',                           │
│         calculateTodayRevenue()                                       │
│       );                                                              │
│     })                                                                │
│   .subscribe();                                                       │
│ ```                                                                    │
│                                                                         │
│ Dashboard Cards:                                                       │
│ • Live: Leads this hour                                               │
│ • Live: Orders in progress                                            │
│ • Live: Revenue today                                                 │
│ • Live: Top Reel (by conversions)                                     │
│                                                                         │
│ Success:    Real-time updates without page refresh                    │
│ Latency:    < 500ms                                                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 3: WEEKLY REPORT GENERATION                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Cron: Monday 6 AM                                         │
│                                                                         │
│ Workflow:   REPORT_WEEKLY                                             │
│ Logic:      • Compile:                                                 │
│               - Total revenue (last 7 days)                           │
│               - Top 3 Reels (by ROAS)                                │
│               - Conversion rate trend                                 │
│               - Customer breakdown (new vs repeat)                    │
│               - Avg order value                                        │
│               - Projected monthly revenue                             │
│             • Format as:                                              │
│               - PDF report                                            │
│               - WhatsApp message with key stats                       │
│               - Email (if available)                                  │
│                                                                         │
│ Sample Message:                                                        │
│ "📊 Weekly Summary                                                    │
│  💰 Revenue: KSh 45,000 (+25% vs last week)                          │
│  👥 New customers: 42                                                 │
│  🎬 Top Reel: Product Launch (12.5% ROAS)                           │
│  🎯 Proj. MRR: KSh 180K                                              │
│  📈 Trend: Up ↗️"                                                     │
│                                                                         │
│ Database:   INSERT INTO reports (type, data, sent_at)                 │
│                                                                         │
│ Success:    Report delivered                                          │
│ Impact:     Shows "magic" of the platform                             │
└─────────────────────────────────────────────────────────────────────────┘
```

### **2.5 Compliance & Safety Flow (KRA eTIMS)**

**Business Need**: "Stay compliant without thinking"  
**Nairobi Regulatory**: KRA eTIMS mandatory 2026 [5][6]

```
┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: INVOICE GENERATION                                              │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    DB trigger: orders.status → 'paid'                        │
│                                                                         │
│ Workflow:   KRA_INVOICE_CREATOR                                       │
│ Logic:      • Generate invoice on payment:                            │
│               - Invoice number: INV-{tenant-id}-{sequence}            │
│               - Items: order line items                               │
│               - Tax: 16% VAT (Kenyan standard)                       │
│               - Total: amount + tax                                   │
│             • Format for eTIMS API:                                   │
│               {                                                        │
│                 "invoiceNumber": "INV-...",                          │
│                 "invoiceDate": "2026-01-09",                        │
│                 "buyerName": "Customer",                             │
│                 "buyerPhone": "0700...",                             │
│                 "lineItems": [...],                                  │
│                 "totalAmount": 500,                                  │
│                 "taxAmount": 80,                                     │
│                 "netAmount": 420                                     │
│               }                                                        │
│                                                                         │
│ Database:   INSERT INTO invoices (                                    │
│               tenant_id, order_id, invoice_number,                   │
│               total_amount, tax_amount, pdf_url, eTIMS_id            │
│             )                                                         │
│                                                                         │
│ Success:    Invoice record created                                    │
│ Future:     Auto-submit to eTIMS API (Week 9+)                       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 2: INVOICE DELIVERY                                                │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    invoices.created                                           │
│                                                                         │
│ Workflow:   WA_RECEIPT_SENDER                                         │
│ Logic:      • Generate PDF (HTML → PDF via wkhtmltopdf)              │
│             • Upload to Supabase storage                              │
│             • Send to customer:                                       │
│               "✅ Payment confirmed                                    │
│                📃 Invoice: INV-123456                                 │
│                💰 Total: KSh 580 (incl. tax)                         │
│                📥 [Invoice link]"                                     │
│             • Save message_id for tracking                            │
│                                                                         │
│ Database:   UPDATE invoices SET                                        │
│               pdf_url = $url,                                          │
│               sent_to_customer = true                                 │
│                                                                         │
│ Success:    Invoice delivered to customer                             │
│ Compliance: Audit trail for KRA                                       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 3: TAX REPORTING (Monthly/Quarterly)                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Cron: End of month + quarterly                            │
│                                                                         │
│ Workflow:   KRA_TAX_REPORT                                            │
│ Logic:      • Aggregate for tax period:                                │
│               SELECT SUM(net_amount) as gross,                        │
│                      SUM(tax_amount) as tax_collected                 │
│               FROM invoices WHERE date_range                          │
│             • Generate tax report:                                    │
│               - Gross sales                                           │
│               - Tax due (KRA can send auto-payment request)           │
│               - Exemptions (if any)                                      │
│             • Alert owner: "Tax payment due: KSh XXX"                │
│                                                                         │
│ Database:   INSERT INTO tax_reports (...)                             │
│                                                                         │
│ Success:    Owner prepared for KRA                                    │
│ Future:     Auto-submit to KRA eTIMS API                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 4: DATA BACKUP & COMPLIANCE                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Trigger:    Cron: Daily 3 AM                                          │
│                                                                         │
│ Workflow:   BACKUP_DAILY                                              │
│ Logic:      • Export tenant data:                                      │
│               - All tables (orders, payments, invoices, etc)         │
│               - Format: JSON + CSV                                    │
│               - Encrypt: AES-256                                      │
│             • Store in:                                               │
│               - Primary: S3 (AWS)                                     │
│               - Backup: GCS (Google Cloud)                            │
│             • Log: backup_logs table                                  │
│                                                                         │
│ Database:   INSERT INTO backup_logs (...)                             │
│                                                                         │
│ Compliance: Data Protection Act 2019 (Kenya)                          │
│             Personal data backed up securely                          │
│ Recovery:   Any breach → 48-hour restore capability                   │
└─────────────────────────────────────────────────────────────────────────┘
```

***

## **3. WORKFLOW INTERDEPENDENCY MATRIX (NAIROBI EDITION)**

```
Workflow               │ Triggers                      │ Triggered By            │ Critical?
───────────────────────┼───────────────────────────────┼─────────────────────────┼──────────
IG_LEAD_CAPTURE        │ Instagram webhook             │ None                    │ ⭐⭐⭐
WA_INITIAL_CONTACT     │ leads.status = 'new'          │ IG_LEAD_CAPTURE        │ ⭐⭐
WA_ORDER_PARSER        │ WhatsApp webhook              │ None                    │ ⭐⭐⭐
MP_STK_TRIGGER         │ orders.status = 'created'     │ WA_ORDER_PARSER        │ ⭐⭐⭐
MP_RECONCILER          │ M-Pesa webhook (C2B)          │ None                    │ ⭐⭐⭐⭐⭐
DEL_ETA_ESTIMATOR      │ orders.status = 'paid'        │ MP_RECONCILER          │ ⭐⭐
WA_ETA_NOTIFIER        │ orders.delivery_eta set       │ DEL_ETA_ESTIMATOR      │ ⭐⭐
INV_STOCK_CHECK        │ Cron (30 min) + inv.updated   │ None                    │ ⭐⭐
WA_BROADCAST_ALERT     │ inventory.low_stock = true    │ INV_STOCK_CHECK        │ ⭐
WA_OOS_HANDLER         │ WA message + inventory check  │ WA_ORDER_PARSER        │ ⭐⭐
KRA_INVOICE_CREATOR    │ orders.status = 'paid'        │ MP_RECONCILER          │ ⭐⭐
WA_RECEIPT_SENDER      │ invoices.created              │ KRA_INVOICE_CREATOR    │ ⭐
ANALYTICS_DAILY        │ Cron (2 AM)                   │ None                    │ ⭐⭐
ANALYTICS_REALTIME     │ Supabase changes (live)       │ None                    │ ⭐⭐
REPORT_WEEKLY          │ Cron (Monday 6 AM)            │ ANALYTICS_DAILY        │ ⭐
BACKUP_DAILY           │ Cron (3 AM)                   │ None                    │ ⭐⭐⭐⭐
```

**Critical Workflows (Must be 99.9% uptime):**
- MP_RECONCILER (if this fails, payments don't process)
- WA_ORDER_PARSER (fuels revenue engine)
- IG_LEAD_CAPTURE (top of funnel)

***

## **4. NAIROBI-SPECIFIC ORCHESTRATION PATTERNS**

### **4.1 The Sheng Voice Parsing Pattern**

```javascript
// PATTERN: WhatsApp Voice → Sheng/Somali → Order
// Common Nairobi phrases parsed:

const shengPatterns = {
  // Stock inquiries
  "pesa iko": "Is this available?",
  "stock ni sawa": "Is stock OK?",
  "kitu iko?": "Is it in stock?",
  
  // Price inquiries (Somali + Sheng)
  "bei ngapi": "How much?",
  "kiasi gani": "What's the price?",
  "qiyada": "The price?",
  
  // Order placement
  "nimtaka pairs": "I want pairs",
  "nataka units": "I want units",
  "napenda ...": "I like...",
  
  // Delivery/logistics
  "delivery eko aje": "How is delivery?",
  "kukaa hapa": "For this area",
  "manambane": "Tonight/tomorrow",
};

// Confidence scoring:
// - Exact phrase match = 0.95 confidence
// - Partial match + context = 0.80 confidence
// - Uncertain = flag for manual review
```

### **4.2 The M-Pesa Fee-Inclusive Pattern**

```sql
-- Nairobi SMEs often pay M-Pesa fees out of pocket
-- "I want item for KSh 500, M-Pesa costs KSh 25"
-- Customer sends: 525 KSh, orders for: 500 KSh

-- CREATE fuzzy range based on fee structure:
SELECT fee_amount FROM mpesa_fees 
WHERE transaction_amount BETWEEN $amount * 0.99 AND $amount * 1.05;

-- Fuzzy tolerance: base ±15 KSh + M-Pesa fee range
-- This captures: exact, fee-included, and honest confusion
```

### **4.3 The Multi-Tenant Tenant Isolation Pattern**

```javascript
// EVERY workflow extracts tenant_id like this:

async function extractTenantContext(webhook) {
  let tenantId;
  
  // Path parameter: /webhook/meta/:tenant_id
  if (webhook.params.tenant_id) {
    tenantId = webhook.params.tenant_id;
  }
  // Phone lookup: WhatsApp sender → tenant
  else if (webhook.body.from) {
    const phone = normalizePhone(webhook.body.from);
    const tenant = await db
      .from('tenants')
      .select('id')
      .eq('whatsapp_number', phone)
      .single();
    tenantId = tenant.id;
  }
  // Instagram business account → tenant
  else if (webhook.body.business_account_id) {
    const tenant = await db
      .from('tenant_config')
      .select('tenant_id')
      .eq('instagram_business_account_id', webhook.body.business_account_id)
      .single();
    tenantId = tenant.tenant_id;
  }
  
  // RLS enforces: every query must include this
  return {
    tenantId,
    rls_scope: `tenant_id = '${tenantId}'::uuid`
  };
}
```

***

## **5. THE 14 CORE WORKFLOWS (PRODUCTION-READY SPECS)**

### **5.1 CRITICAL PATH (Week 1: Revenue Engine)**

#### **Workflow 1: MP_RECONCILER** (Most Important)
```
NAME: M-Pesa Payment Reconciliation
TRIGGER: POST /webhook/mpesa/:tenant_id
PURPOSE: Match M-Pesa payment to order (98.5% auto-match)
INPUTS:
  - mpesa_receipt_number (unique)
  - amount
  - phone
  - timestamp
OUTPUTS:
  - order.status = 'paid'
  - payment record created
  - invoice triggered
FAILURE_PATH: DLQ + admin WhatsApp alert
TIMEOUT: 5 seconds
RETRY: 3x with exponential backoff
SUCCESS_RATE_TARGET: 98.5% auto-match
```

#### **Workflow 2: WA_ORDER_PARSER**
```
NAME: WhatsApp Order Extraction & Validation
TRIGGER: POST /webhook/meta/:tenant_id (message)
PURPOSE: Parse "I want 2 pairs" → create order
INPUTS:
  - message (text/voice/button)
  - from phone
  - message_id (idempotency)
OUTPUTS:
  - order created
  - MP_STK_TRIGGER called
PATHS:
  - Text parsing (regex)
  - Voice parsing (Google Speech-to-Text)
  - Button reply (JSON)
CONFIDENCE_THRESHOLD: > 80% (< 80% → manual review)
SUCCESS_RATE_TARGET: 90%+ first-time accuracy
```

#### **Workflow 3: IG_LEAD_CAPTURE**
```
NAME: Instagram Comment → Lead Extraction
TRIGGER: POST /webhook/meta/:tenant_id (comment)
PURPOSE: Convert "YES" comment into lead
INPUTS:
  - comment text
  - author handle
  - reel_id
  - campaign_id
OUTPUTS:
  - lead created
  - WA_INITIAL_CONTACT triggered
ENRICHMENT:
  - Phone lookup from bio
  - Location extraction
  - Influencer tagging
SUCCESS_RATE_TARGET: 95%+ lead creation
```

### **5.2 SECONDARY PATH (Week 2: Scale & Trust)**

#### **Workflow 4: MP_STK_TRIGGER**
```
NAME: M-Pesa STK Push Initiation
TRIGGER: orders.status = 'created'
PURPOSE: Send payment prompt to customer
INPUTS:
  - order_id, amount, phone
OUTPUTS:
  - STK appears on customer phone
  - checkout_request_id stored
API: Safaricom Daraja STK Push
SUCCESS_RATE_TARGET: 99%+ (near-instant)
```

#### **Workflow 5: WA_INITIAL_CONTACT**
```
NAME: Catalog Delivery to New Lead
TRIGGER: leads.status = 'new'
PURPOSE: Send product catalog via WhatsApp
INPUTS:
  - lead_id, phone, tenant_id
OUTPUTS:
  - catalog message sent
  - leads.status = 'contacted'
TEMPLATE: Meta-approved WhatsApp template
SUCCESS_RATE_TARGET: 98%+ delivery
```

#### **Workflow 6: DEL_ETA_ESTIMATOR**
```
NAME: Delivery ETA Calculation
TRIGGER: orders.status = 'paid'
PURPOSE: Estimate delivery time based on zone + history
INPUTS:
  - order_id, delivery_zone, product
OUTPUTS:
  - delivery_eta calculated
  - delivery_method assigned (Glovo/Sendy/self)
ALGORITHM:
  - Historical avg for zone
  - Buffer for traffic
  - Seasonal adjustment
SUCCESS_RATE_TARGET: 85%+ within 2-hour window
```

#### **Workflow 7: WA_ETA_NOTIFIER**
```
NAME: Delivery Status Updates
TRIGGER: orders.delivery_eta set OR partner webhook
PURPOSE: Keep customer updated on delivery
INPUTS:
  - order_id, delivery_eta, status
OUTPUTS:
  - WhatsApp message sent
  - SMS fallback (if WA fails)
FREQUENCY: ETA notification, delay alerts
SUCCESS_RATE_TARGET: 99%+ notification delivery
```

#### **Workflow 8: INV_STOCK_CHECK**
```
NAME: Stock Level Monitoring
TRIGGER: Cron (every 30 min) + inventory updates
PURPOSE: Detect low stock before overselling
INPUTS:
  - all inventory items
OUTPUTS:
  - alert_sent for low stock items
LOGIC:
  - Query items below min_threshold
  - Check last alert (prevent spam)
  - Calculate days until stockout
SUCCESS_RATE_TARGET: 100% detection
```

### **5.3 INTELLIGENCE PATH (Week 3-4: Stickiness)**

#### **Workflow 9: ANALYTICS_DAILY**
```
NAME: Daily Metrics Aggregation
TRIGGER: Cron (2 AM daily)
PURPOSE: Calculate ROAS, conversion, revenue
INPUTS:
  - yesterday's leads, orders, payments
OUTPUTS:
  - analytics_daily record
METRICS:
  - Lead count
  - Conversion rate (orders / leads)
  - Revenue (paid orders)
  - ROAS per Reel
  - ROAS per Campaign
SUCCESS_RATE_TARGET: 100% (no dropped calculations)
```

#### **Workflow 10: ANALYTICS_REALTIME**
```
NAME: Real-time Dashboard Updates
TRIGGER: Supabase Realtime (any table change)
PURPOSE: Live dashboard (no page refresh needed)
INPUTS:
  - WebSocket stream
OUTPUTS:
  - Browser receives updates
  - Cards update instantly
TECHNOLOGIES:
  - Supabase Realtime
  - WebSocket
  - React hooks (useEffect)
LATENCY_TARGET: < 500ms end-to-end
```

#### **Workflow 11: REPORT_WEEKLY**
```
NAME: Weekly Summary Report
TRIGGER: Cron (Monday 6 AM)
PURPOSE: Show SME what platform delivered
INPUTS:
  - last 7 days data
OUTPUTS:
  - PDF report
  - WhatsApp summary message
CONTENT:
  - Revenue
  - Top Reels
  - Conversion trends
  - Customer stats
  - MRR projection
SUCCESS_RATE_TARGET: 100% delivery (shows value)
```

#### **Workflow 12: KRA_INVOICE_CREATOR**
```
NAME: Invoice Generation (eTIMS Ready)
TRIGGER: orders.status = 'paid'
PURPOSE: Create invoice for compliance + customer
INPUTS:
  - order_id, items, tax
OUTPUTS:
  - invoice created
  - PDF stored
  - eTIMS-compatible JSON
COMPLIANCE: Kenya VAT 16%
SUCCESS_RATE_TARGET: 100% (no lost invoices)
```

#### **Workflow 13: WA_OOS_HANDLER**
```
NAME: Out-of-Stock Management
TRIGGER: WA_ORDER_PARSER detects OOS
PURPOSE: Prevent overselling, suggest alternatives
INPUTS:
  - requested product, quantity
OUTPUTS:
  - Waitlist created OR alternative suggested
LOGIC:
  - Check if alternatives exist
  - Suggest similar products
  - Offer pre-order (if enabled)
SUCCESS_RATE_TARGET: 80%+ customer retention on OOS
```

#### **Workflow 14: BACKUP_DAILY**
```
NAME: Secure Data Backup
TRIGGER: Cron (3 AM daily)
PURPOSE: Protect tenant data (compliance + recovery)
INPUTS:
  - all tenant tables
OUTPUTS:
  - encrypted backup (S3 + GCS)
  - backup_logs record
ENCRYPTION: AES-256
RETENTION: 90 days
RECOVERY_TIME: < 4 hours
SUCCESS_RATE_TARGET: 100% (zero data loss)
```

***

## **6. ERROR HANDLING & RESILIENCE (The Safety Net)**

### **6.1 The Circuit Breaker Pattern**

```javascript
// When API is down (M-Pesa, WhatsApp, etc)
// Don't keep retrying - break the circuit

class CircuitBreaker {
  constructor(apiName, failureThreshold = 5, resetTimeout = 60000) {
    this.apiName = apiName;
    this.failureCount = 0;
    this.failureThreshold = failureThreshold;
    this.resetTimeout = resetTimeout;
    this.state = 'CLOSED'; // CLOSED → OPEN → HALF_OPEN → CLOSED
  }

  async call(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error(`Circuit breaker OPEN for ${this.apiName}`);
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
      console.log(`⚠️  Circuit breaker OPEN for ${this.apiName}`);
    }
  }
}

// Usage in MP_RECONCILER:
const mpesaBreaker = new CircuitBreaker('mpesa');
try {
  await mpesaBreaker.call(() => 
    verifyMpesaSignature(webhook)
  );
} catch (error) {
  // If M-Pesa API is down, put payment in DLQ
  // Don't cascade failure to other workflows
  await insertIntoDLQ({
    type: 'payment',
    payload: webhook,
    reason: 'M-Pesa circuit breaker open'
  });
}
```

### **6.2 The Dead Letter Queue Pattern**

```sql
-- Failed workflows go here for manual retry

CREATE TABLE dead_letter_queue (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  workflow_name VARCHAR,
  item_type VARCHAR,  -- 'payment', 'order', 'lead'
  item_id VARCHAR,
  error_message TEXT,
  payload JSONB,
  attempt_count INT DEFAULT 1,
  next_retry_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Example: M-Pesa payment couldn't be reconciled
INSERT INTO dead_letter_queue (
  tenant_id, workflow_name, item_type, item_id,
  error_message, payload, next_retry_at
) VALUES (
  'tenant-uuid',
  'MP_RECONCILER',
  'payment',
  'NLJ7FF5ZX0',
  'No matching order found (amount 525, ±15 tolerance)',
  '{"mpesa_receipt": "...", ...}',
  NOW() + INTERVAL '30 minutes'
);

-- Cron job: Every 30 minutes, retry DLQ items
SELECT * FROM dead_letter_queue 
WHERE next_retry_at <= NOW()
ORDER BY attempt_count ASC
LIMIT 100;

-- After successful retry:
DELETE FROM dead_letter_queue WHERE id = $dlq_id;
```

***

## **7. PRODUCTION DEPLOYMENT & MONITORING**

### **7.1 The Orchestration Deployment Architecture**

```
Production Environment (AWS/GCP):
├── n8n Instance (webhook receivers)
│   ├─ /webhook/meta/:tenant_id (Instagram + WhatsApp)
│   ├─ /webhook/mpesa/:tenant_id (M-Pesa payments)
│   ├─ /webhook/cron/:workflow_id (scheduled)
│   └─ Load balanced (2+ instances for failover)
│
├── Supabase Project (state machine + RLS)
│   ├─ Primary: PostgreSQL (Nairobi region)
│   ├─ Backups: 24-hour retention
│   ├─ Replication: Cross-region for resilience
│   └─ Monitoring: Datadog/New Relic
│
├── Secrets Management
│   ├─ Meta access tokens (Vault)
│   ├─ M-Pesa credentials (Vault)
│   ├─ Encryption keys (HSM)
│   └─ Auto-rotation: 90 days
│
└── Monitoring & Alerts
    ├─ Slack channel: #orchestration-errors
    ├─ PagerDuty: Critical failures
    ├─ Datadog: Real-time metrics
    └─ Grafana: Custom dashboards
```

### **7.2 Key Metrics to Monitor**

```
ORCHESTRATION HEALTH:
✅ Workflow Success Rate (Target: 99.5%+)
✅ API Latency P95 (Target: < 2 seconds)
✅ Dead Letter Queue Size (Target: < 10 items)
✅ Webhook Processing Time (Target: < 1 second)

BUSINESS METRICS:
✅ Lead-to-Payment Time (Target: < 5 minutes)
✅ Payment Auto-Match Rate (Target: 98.5%+)
✅ Customer Conversion Rate (Target: 30%+)
✅ Order Fulfillment Rate (Target: 99%+)

SECURITY METRICS:
✅ Tenant Isolation Score (Target: 100%)
✅ Data Encryption Coverage (Target: 100%)
✅ Backup Completion Rate (Target: 100%)
✅ Audit Log Completeness (Target: 100%)
```

***

## **8. THE MAGIC FORMULA (Orchestration Completeness)**

```
Naive Approach:
Instagram Ads → WhatsApp (manual) → M-Pesa (manual) → Excel
= 40% conversion, high error rate, slow scaling

Your Approach (Orchestration):
Instagram (auto-lead) ⚡ WhatsApp (auto-order) ⚡ M-Pesa (auto-payment)
  ⚡ Inventory (auto-check) ⚡ Delivery (auto-eta) ⚡ Analytics (auto-insight)
= 30%+ conversion, <1% error, instant scaling

Competitor Approach:
Instagram → 3rd party tool → WhatsApp → 3rd party tool → Excel
= Fragmented, data silos, expensive (KSh 10K+)

YOUR ADVANTAGE:
Complete orchestration network = unfragmented automation
= Price advantage (KSh 1,499 vs KSh 10K)
= Feature advantage (attribution + voice parsing + inventory)
= Scale advantage (n8n JSON = clone customer in 15 mins)
```

***

## **9. QUICK REFERENCE: CRITICAL WORKFLOW FLOWCHARTS**

### **MP_Reconciler Decision Tree**

```
M-Pesa Webhook
    ↓
{Verify Signature}
    ↓ (Invalid) → ❌ Reject + Log Attack
    ↓ (Valid)
{Check Idempotency: MpesaReceipt exists?}
    ↓ (Yes) → ✅ Return Success (Already processed)
    ↓ (No)
{Find Order: Exact Match?}
    ↓ (Yes) → ✅ Auto-Reconcile (Confidence: 1.0)
    ↓ (No)
{Fuzzy Match: ±15 KSh}
    ↓ (No match) → ⏳ Queue for Review
    ↓ (Match found)
{Confidence > 0.9?}
    ↓ (Yes) → ✅ Auto-Reconcile (Confidence: 0.90+)
    ↓ (No) → ⏳ Queue for Review + Admin Alert
    ↓
Update orders.status = 'paid'
    ↓
Trigger: DEL_ETA_ESTIMATOR
Trigger: KRA_INVOICE_CREATOR
```

***

## **10. WEEK-BY-WEEK ORCHESTRATION BUILD**

### **Week 1: The Money Pipeline**

```
Day 1: MP_RECONCILER
  ✅ Verify M-Pesa webhook signature
  ✅ Implement exact + fuzzy matching
  ✅ Test with real M-Pesa (sandbox)
  Success: 98.5% auto-match rate

Day 2-3: WA_ORDER_PARSER + MP_STK_TRIGGER
  ✅ Text parsing (regex patterns)
  ✅ Voice parsing (Google STT)
  ✅ STK Push integration
  Success: < 5 second order creation

Day 4: IG_LEAD_CAPTURE + WA_INITIAL_CONTACT
  ✅ Comment webhook
  ✅ Phone extraction
  ✅ Catalog handoff
  Success: 95%+ lead creation

Day 5: Analytics + Hardening
  ✅ Basic dashboard (leads → revenue)
  ✅ Error handlers (retry + DLQ)
  ✅ SMS fallback
  Success: MVP live, KSh 7.5K-15K MRR
```

### **Week 2: Trust & Scale**

```
Day 1-2: DEL_ETA_ESTIMATOR + WA_ETA_NOTIFIER
  ✅ Zone-based ETA calculation
  ✅ Realtime delivery tracking
  Success: 85%+ accuracy

Day 3: INV_STOCK_CHECK + WA_OOS_HANDLER
  ✅ Stock alerts
  ✅ Alternative suggestions
  Success: 0% overselling

Day 4: Circuit Breakers + DLQ Processor
  ✅ API resilience
  ✅ Manual override UI
  Success: No cascade failures

Day 5: Multi-Tenant Isolation Testing
  ✅ Cross-tenant data leak tests
  ✅ RLS policy verification
  Success: 100% isolation
```

### **Week 3-4: Intelligence & Compliance**

```
Day 1-2: ANALYTICS_DAILY + ANALYTICS_REALTIME
  ✅ ROAS per Reel
  ✅ Live dashboard
  Success: Shows customer "magic"

Day 3: KRA_INVOICE_CREATOR + REPORT_WEEKLY
  ✅ Invoice generation
  ✅ Tax reporting (prep for eTIMS)
  Success: Compliance ready

Day 4: BACKUP_DAILY + Data Recovery Tests
  ✅ Automated backups
  ✅ Restore procedure tested
  Success: Zero-data-loss guarantee

Day 5: Production Go-Live
  ✅ All workflows tested
  ✅ Monitoring active
  Success: KSh 50K MRR, 33 customers
```

***

## **FINAL INSIGHT: The Orchestration Mindset**

You're not building a "WhatsApp order bot."

You're building a **revenue orchestration engine** where:
- Instagram = Discovery instrument
- WhatsApp = Sales instrument
- M-Pesa = Fulfillment instrument
- Analytics = Feedback loop
- Inventory = Risk management
- Delivery = Trust building
- Compliance = Defensibility

Your n8n workflows are the **conductor's baton**.

Your Supabase database is the **orchestra's score**.

Each webhook is a **note** that must hit perfectly on time.

Tenants are **different performances** of the same score.

***

## **THE FINAL CHEAT CODE**

Start with **MP_RECONCILER**. 

If payments match automatically with 98.5% accuracy, everything else is decoration.

If they don't, nothing else matters.

The orchestration network rises or falls on this one workflow.

***

**Status: Production Ready**  
**Revenue Timeline: Week 1 launch (Day 7)**  
**MRR Week 4: KSh 50K (33 customers)**  
**Scaling: Add customer in 15 mins (n8n JSON + env vars)**

***

*This is your complete orchestration blueprint. Every use case → workflow → outcome is mapped. The magic is in the connections, not the components. The automation is in the system, not the code. Now go orchestrate Nairobi's digital revenue revolution.*

***

**End of NAIROBI SUPER SUITE: THE ORCHESTRATION MASTER DOCUMENT** ✅