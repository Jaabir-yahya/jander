# **SPEC COMPLIANCE ACTION PLAN: GET TO 100%**

**Date:** January 9, 2026  
**Current Compliance:** 78%  
**Target:** 100%  
**Timeline:** Week 2-4

---

## **PRIORITY 1: CRITICAL GAPS (Week 2) - Block Revenue Engine**

### **1.1 Inventory Infrastructure** 🔴 **CRITICAL**

**Why:** Cannot prevent overselling without inventory tracking

**Required:**
1. **Database Migration:** `012_create_inventory_tables.sql`
   - Table: `inventory` (product_id, tenant_id, quantity, min_threshold, alert_sent_at)
   - Table: `waitlist` (customer, product, priority, created_at)
   - RLS policies
   - Indexes

2. **Workflow:** `22_inv_stock_check.json`
   - Trigger: Cron (every 30 minutes)
   - Logic: Query low stock items, calculate days until stockout
   - Output: Trigger WA_BROADCAST_ALERT

3. **Workflow:** `23_wa_broadcast_alert.json`
   - Trigger: inventory.alert_sent_at updated
   - Logic: Format stock alert message, send to owner WhatsApp
   - Output: Owner notified

4. **Workflow:** `24_wa_oos_handler.json`
   - Trigger: WA_ORDER_PARSER detects OOS
   - Logic: Check alternatives, suggest similar products, create waitlist
   - Output: Waitlist created OR alternative suggested

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.2

---

### **1.2 Delivery Infrastructure** 🔴 **CRITICAL**

**Why:** Cannot provide delivery ETAs without delivery tracking

**Required:**
1. **Database Migration:** `013_create_delivery_tables.sql`
   - Table: `deliveries` (order_id, tenant_id, zone, estimated_delivery_at, delivery_method, partner_id, status)
   - Table: `delivery_partners` (id, name, api_endpoint, enabled)
   - RLS policies
   - Indexes

2. **Workflow:** `25_del_eta_estimator.json`
   - Trigger: `orders.status = 'paid'` (DB trigger or webhook)
   - Logic: Extract zone, query historical avg, calculate ETA with buffer
   - Output: orders.delivery_eta set, delivery record created

3. **Workflow:** `26_wa_eta_notifier.json`
   - Trigger: orders.estimated_delivery_at set
   - Logic: Format ETA message, send to customer WhatsApp
   - Output: Customer notified

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.3

---

### **1.3 WA_ORDER_PARSER Enhancement** 🟡 **HIGH**

**Why:** Cannot handle voice orders (Sheng/Somali) - critical for Nairobi market

**Current:** `01_classify_message_v2.json` handles text classification

**Required Enhancements:**
1. **Voice Parsing Branch:**
   - Detect voice message type
   - Call Google Cloud Speech-to-Text API
   - Language detection (English/Swahili/Sheng/Somali)
   - Parse transcript for order details
   - Confidence scoring (< 80% → manual review)

2. **WhatsApp Flows Support:**
   - Detect Flow form submission
   - Extract structured data from Flow JSON
   - Create order from Flow data

3. **Order Creation Logic:**
   - Verify order creation happens after parsing
   - Ensure MP_STK_TRIGGER is called

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.1 Step 3

---

### **1.4 MP_STK_TRIGGER Verification** 🟡 **HIGH**

**Why:** Need to ensure STK Push auto-triggers on order creation

**Current:** `09_multi_rail_payment.json` has STK Push logic

**Required Verification:**
1. Check if `10_handle_order_with_confirmation.json` triggers STK Push
2. If not, create separate `27_mp_stk_trigger.json` workflow
3. Trigger: DB trigger on `orders.status = 'created'`
4. Logic: Call M-Pesa STK Push API, store checkout_request_id

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.1 Step 4

---

## **PRIORITY 2: IMPORTANT GAPS (Week 3) - Intelligence & Compliance**

### **2.1 ANALYTICS_DAILY Workflow** 🟡 **MEDIUM**

**Why:** Need ROAS per Reel/Campaign calculation (different from hourly)

**Current:** `15_analytics_hourly.json` exists (hourly metrics)

**Required:**
1. **Workflow:** `28_analytics_daily.json`
   - Trigger: Cron (2 AM daily)
   - Logic: 
     - Query yesterday's leads, orders, payments
     - Calculate ROAS per Reel (revenue / ad_spend)
     - Calculate ROAS per Campaign
     - Update `analytics_daily_summary` materialized view
   - Output: Daily analytics record

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.4 Step 1

---

### **2.2 REPORT_WEEKLY Workflow** 🟢 **LOW**

**Why:** Weekly summary shows platform value to customers

**Required:**
1. **Workflow:** `29_report_weekly.json`
   - Trigger: Cron (Monday 6 AM)
   - Logic:
     - Query last 7 days data
     - Calculate: Revenue, Top Reels, Conversion trends, Customer stats, MRR projection
     - Generate PDF report
     - Send WhatsApp summary message
   - Output: PDF stored, WhatsApp message sent

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.4 Step 3

---

## **PRIORITY 3: NICE-TO-HAVE (Week 4) - Production Hardening**

### **3.1 BACKUP_DAILY Workflow** 🟢 **LOW**

**Why:** Data protection and compliance requirement

**Required:**
1. **Workflow:** `30_backup_daily.json`
   - Trigger: Cron (3 AM daily)
   - Logic:
     - Export all tenant tables (orders, payments, invoices, etc.)
     - Encrypt with AES-256
     - Upload to S3 (primary) + GCS (backup)
     - Log to backup_logs table
   - Output: Encrypted backup stored, log entry created

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.5 Step 4

---

### **3.2 ANALYTICS_REALTIME** 🟢 **LOW**

**Why:** Client-side implementation (not n8n workflow)

**Note:** This is a frontend implementation using Supabase Realtime WebSockets, not an n8n workflow. Should be documented but not built as workflow.

**Required:**
1. **Documentation:** Client-side implementation guide
2. **Supabase Realtime:** Enable on relevant tables
3. **React/Next.js:** WebSocket connection example

**Reference:** `docs/core/NAIROBI_ORCHESTRATION_MASTER.md` Section 2.4 Step 2

---

## **4. WORKFLOW VERIFICATION CHECKLIST**

### **Verify Existing Workflows Match Spec:**

- [ ] **WA_INITIAL_CONTACT:** Verify `03_send_whatsapp_v2.json` triggers on `leads.status = 'new'`
- [ ] **WA_ORDER_PARSER:** Verify order creation happens in `01_classify_message_v2.json` or `10_handle_order_with_confirmation.json`
- [ ] **MP_STK_TRIGGER:** Verify STK Push triggers on order creation
- [ ] **KRA_INVOICE_CREATOR:** Verify `08_submit_to_etims.json` creates invoice records (may need invoices table)

---

## **5. BUILD ORDER (WEEK-BY-WEEK)**

### **Week 2: Critical Infrastructure**
1. Day 1-2: Build inventory infrastructure (table + 3 workflows)
2. Day 3-4: Build delivery infrastructure (table + 2 workflows)
3. Day 5: Enhance WA_ORDER_PARSER (voice parsing, WhatsApp Flows)

### **Week 3: Intelligence & Reports**
1. Day 1-2: Build ANALYTICS_DAILY workflow
2. Day 3: Build REPORT_WEEKLY workflow
3. Day 4-5: Testing & refinement

### **Week 4: Production Hardening**
1. Day 1-2: Build BACKUP_DAILY workflow
2. Day 3: Document ANALYTICS_REALTIME (client-side)
3. Day 4-5: Final testing & go-live prep

---

## **6. SUCCESS CRITERIA**

### **Week 2 Complete:**
- ✅ Inventory infrastructure operational
- ✅ Delivery infrastructure operational
- ✅ WA_ORDER_PARSER handles voice orders
- ✅ MP_STK_TRIGGER verified/working

### **Week 3 Complete:**
- ✅ ANALYTICS_DAILY generating ROAS insights
- ✅ REPORT_WEEKLY sending weekly summaries

### **Week 4 Complete:**
- ✅ BACKUP_DAILY protecting data
- ✅ 100% spec compliance achieved

---

## **7. RISK MITIGATION**

### **If Inventory Not Built:**
- **Risk:** Overselling, lost customer trust
- **Mitigation:** Manual stock checks until automated

### **If Delivery Not Built:**
- **Risk:** "Where's my order?" complaints increase
- **Mitigation:** Manual ETA communication via WhatsApp

### **If Voice Parsing Not Built:**
- **Risk:** 20-30% of orders lost (voice note orders)
- **Mitigation:** Manual transcription, flag for review

---

**Status:** Action plan ready for execution  
**Next:** Start with Priority 1 (Inventory & Delivery infrastructure)

