# **INDUSTRY-STANDARD DATA VISUALIZATION & INTELLIGENCE SYSTEM**

**Nairobi Super Suite: From Data to Actionable Intelligence**  
**Date:** January 9, 2026 | Status: Production-Ready Blueprint

---

## **THE CORE PHILOSOPHY**
Data isn't valuable until it becomes **actionable insight**. Nairobi SMEs don't need "dashboards"—they need **daily operational intelligence**. This document outlines the industry-standard approach to transforming your orchestrated data into business value.

---

## **1. INDUSTRY STANDARDS: THE THREE-LAYER PYRAMID**

### **Layer 1: Operational Intelligence (Day-to-Day)**
**Industry Standard**: Real-time KPI dashboards that answer "What's happening RIGHT NOW?"

| Need | Industry Standard | Your Implementation |
|------|-------------------|---------------------|
| **Today's Revenue** | Real-time counter, last 24h vs yesterday | Supabase view: `today_revenue` with WebSocket updates |
| **Pending Orders** | List with status badges (processing, shipping) | `orders.status` filtered views + realtime |
| **Lead Conversion** | Funnel visualization (leads → contacted → ordered) | Pre-calculated hourly aggregates in `analytics_cache` |
| **Stock Alerts** | Visual "low stock" indicators with product images | `inventory.stock_level` threshold views |
| **Delivery Status** | Timeline view of today's deliveries with ETA | `deliveries.timeline` view with driver assignment |

### **Layer 2: Tactical Intelligence (Weekly/Monthly)**
**Industry Standard**: Comparative analytics for "What's working?"

| Need | Industry Standard | Your Implementation |
|------|-------------------|---------------------|
| **ROAS by Reel** | Bar chart comparing ad spend to revenue | `analytics_reel_performance` materialized view |
| **Best-Selling Products** | Ranking table with % of total revenue | `analytics_product_performance` aggregated daily |
| **Customer Segmentation** | RFM matrix (Recency, Frequency, Monetary) | `customers.rfm_score` calculated weekly via n8n |
| **Channel Effectiveness** | Pie chart: Instagram vs WhatsApp vs Walk-in | `analytics_channel_attribution` view |

### **Layer 3: Strategic Intelligence (Quarterly)**
**Industry Standard**: Trends, forecasts, and "What should we do next?"

| Need | Industry Standard | Your Implementation |
|------|-------------------|---------------------|
| **Revenue Forecast** | 30-day projection based on trends | Simple linear regression on `revenue_daily` |
| **Customer Lifetime Value** | Predicted LTV based on past behavior | Calculated in `analytics_customer_ltv` |
| **Seasonality Patterns** | Year-over-year comparison | Month-over-month growth % in `analytics_seasonality` |
| **Inventory Turnover** | Days of inventory remaining forecast | Based on `sales_velocity` calculated weekly |

---

## **2. THE N8N SUPERPOWER: DATA PIPELINE ORCHESTRATION**

Your n8n workflows don't just move data—they **transform** it into intelligence.

### **2.1 The Intelligence Generation Workflows**

```
INTELLIGENCE_WORKFLOWS:
├── ANALYTICS_Hourly (Cron: Every hour)
│   └── Purpose: Pre-calculates metrics for fast dashboard load
│   
├── ANALYTICS_Daily (Cron: 2 AM daily)  
│   └── Purpose: Creates daily aggregates, ROAS calculations
│
├── ANALYTICS_Weekly (Cron: Sunday 3 AM)
│   └── Purpose: Customer segmentation, inventory turnover
│
├── REPORT_Generator (Trigger: Manual or scheduled)
│   └── Purpose: Creates PDF reports for KRA, bank, partners
│
└── ALERT_Intelligence (Trigger: Data thresholds)
    └── Purpose: Sends proactive insights via WhatsApp
```

### **2.2 The Magic: Turning Raw Data into Insight**

**Example: ROAS Calculation Pipeline**
```
Raw Data → n8n Transformation → Business Insight
──────────   ──────────────────   ──────────────
orders       Aggregate by         ROAS per Reel
+            instagram_reel_id    (Revenue / Ad Spend)
instagram_   
comments
+            Join with
ad_spend     meta_ads data
data
```

**n8n Configuration for This:**
```json
{
  "workflow": "ANALYTICS_ROAS_Calculator",
  "trigger": "Cron (daily 2AM)",
  "steps": [
    "Supabase: Get yesterday's orders with reel_id",
    "Supabase: Get Instagram ad spend per reel",
    "Function: Calculate (revenue / ad_spend) per reel",
    "Supabase: Update analytics_roas_daily table",
    "Function: Flag reels with ROAS < 1.5 for review",
    "WhatsApp: Send alert to owner about low-ROAS reels"
  ]
}
```

---

## **3. SUPA-BASE: YOUR INTELLIGENCE ENGINE ROOM**

### **3.1 The Core Analytics Schema**

```sql
-- MATERIALIZED VIEWS (Refreshed by n8n workflows)
CREATE MATERIALIZED VIEW analytics_daily_summary AS
SELECT 
  tenant_id,
  date,
  COUNT(DISTINCT orders.id) as order_count,
  SUM(orders.total_amount) as revenue,
  COUNT(DISTINCT leads.id) as lead_count,
  ROUND(COUNT(DISTINCT orders.id)::decimal / NULLIF(COUNT(DISTINCT leads.id), 0) * 100, 2) as conversion_rate
FROM tenants
LEFT JOIN leads ON leads.tenant_id = tenants.id 
  AND DATE(leads.created_at) = CURRENT_DATE - INTERVAL '1 day'
LEFT JOIN orders ON orders.tenant_id = tenants.id 
  AND DATE(orders.created_at) = CURRENT_DATE - INTERVAL '1 day'
  AND orders.status = 'paid'
GROUP BY tenant_id, date;

-- REAL-TIME VIEWS (Always current)
CREATE VIEW today_live_dashboard AS
SELECT 
  tenant_id,
  COUNT(CASE WHEN status = 'pending_payment' THEN 1 END) as pending_orders,
  COUNT(CASE WHEN status = 'paid' THEN 1 END) as completed_orders_today,
  SUM(CASE WHEN status = 'paid' AND DATE(created_at) = CURRENT_DATE THEN total_amount ELSE 0 END) as today_revenue,
  ARRAY_AGG(DISTINCT product_name) FILTER (WHERE inventory.stock_level < 5) as low_stock_items
FROM orders
LEFT JOIN inventory ON inventory.tenant_id = orders.tenant_id
WHERE DATE(orders.created_at) = CURRENT_DATE
GROUP BY tenant_id;

-- INTELLIGENCE TABLES (Pre-calculated insights)
CREATE TABLE customer_rfm_scores (
  tenant_id UUID REFERENCES tenants(id),
  customer_phone TEXT,
  recency_score INT, -- Days since last order
  frequency_score INT, -- Orders in last 90 days
  monetary_score INT, -- Total spent in last 90 days
  segment TEXT, -- 'VIP', 'Loyal', 'At Risk', 'Lost'
  last_calculated TIMESTAMP
);
```

### **3.2 The Refresh Strategy**

```yaml
Refresh Schedule:
  - Realtime Views: Always current (PostgreSQL)
  - Hourly Materialized Views: n8n cron every hour
  - Daily Materialized Views: n8n cron at 2 AM
  - Weekly Aggregates: n8n cron Sunday 3 AM
  - Monthly Reports: n8n cron 1st of month 4 AM
```

---

## **4. THE "GOOD ENOUGH" BOOKKEEPING SYSTEM**

### **4.1 What SMEs Actually Need**
Not GAAP-compliant accounting, but:

1. **"How much cash came in today?"**
2. **"Who owes me money?"** 
3. **"What were my expenses?"**
4. **"Can I generate a KRA invoice?"**
5. **"What's my bank balance?"**

### **4.2 The Minimal Viable Bookkeeping Schema**

```sql
-- CORE BOOKKEEPING TABLES
CREATE TABLE cashbook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  transaction_date DATE NOT NULL,
  description TEXT,
  reference TEXT, -- M-Pesa receipt, invoice number
  amount DECIMAL NOT NULL,
  type TEXT CHECK (type IN ('income', 'expense')),
  category TEXT, -- 'sales', 'ad_spend', 'delivery', 'supplies'
  balance_after DECIMAL, -- Running balance
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AUTOMATIC CASHBOOK POPULATION via n8n
-- Workflow: BOOKKEEPING_AutoEntry
-- Trigger: Order paid OR Expense recorded
-- Logic: Insert into cashbook, calculate running balance
```

### **4.3 The n8n Bookkeeping Workflow**

```
WORKFLOW: BOOKKEEPING_DailyClose
Trigger: Cron (10 PM daily)
Steps:
1. Query today's paid orders → Insert as 'income' entries
2. Query today's ad spend from Meta API → Insert as 'expense'
3. Query today's delivery costs → Insert as 'expense'
4. Calculate running balance for the day
5. Generate "Daily Cash Position" WhatsApp message to owner
6. Store PDF backup in Supabase Storage
```

---

## **5. INFORMATION RECALL & ACCESS SYSTEM**

### **5.1 The Three-Access Model**

| **Access Method** | **For** | **Industry Standard** | **Your Implementation** |
|-------------------|---------|----------------------|-------------------------|
| **Instant Recall** | Day-to-day ops | Search bar, filters | Supabase full-text search on orders, customers |
| **Scheduled Reports** | Weekly review | Email PDF, WhatsApp PDF | n8n → Generate PDF → Send via WhatsApp |
| **Deep Analysis** | Quarterly planning | Export to Excel, BI tools | CSV export from Supabase, pre-built templates |

### **5.2 Implementation: The Search & Recall Engine**

```sql
-- ENABLE FULL-TEXT SEARCH
ALTER TABLE orders 
ADD COLUMN search_vector tsvector 
GENERATED ALWAYS AS (
  setweight(to_tsvector('english', COALESCE(customer_phone, '')), 'A') ||
  setweight(to_tsvector('english', COALESCE(items::text, '')), 'B') ||
  setweight(to_tsvector('english', COALESCE(status, '')), 'C')
) STORED;

CREATE INDEX orders_search_idx ON orders USING gin(search_vector);
CREATE INDEX orders_tenant_date_idx ON orders(tenant_id, created_at DESC);

-- SEARCH FUNCTION
CREATE OR REPLACE FUNCTION search_orders(p_tenant_id UUID, query TEXT)
RETURNS TABLE (
  order_id UUID,
  customer_phone TEXT,
  total_amount DECIMAL,
  status TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.customer_phone,
    o.total_amount,
    o.status,
    o.created_at,
    ts_rank(o.search_vector, plainto_tsquery('english', query)) as score
  FROM orders o
  WHERE o.tenant_id = p_tenant_id
    AND o.search_vector @@ plainto_tsquery('english', query)
  ORDER BY score DESC, o.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql;
```

### **5.3 n8n-Powered Report Generation**

```
WORKFLOW: REPORT_WhatsAppDaily
Trigger: Cron (8 AM daily)
Steps:
1. Query yesterday's summary from analytics_daily_summary
2. Query top 3 products from analytics_product_daily
3. Query pending orders count
4. Format as readable message with emojis
5. Send via WhatsApp to business owner

Output: 📊 Daily Report for [Business Name]
        ──────────────────
        ✅ Revenue: KSh 24,500
        ✅ Orders: 18
        ✅ New Leads: 42
        🏆 Top Product: Nike Air (8 sold)
        ⚠️ Pending: 3 orders (KSh 4,200)
        ──────────────────
        View details: [Dashboard Link]
```

---

## **6. DATA SERVING DUAL PURPOSES**

### **6.1 Beyond Dashboard: Data as a Service**

Your data serves **three audiences**:

#### **Audience 1: Business Owner (Primary)**
- **Needs**: Daily operations, cash flow, customer insights
- **Delivery**: WhatsApp alerts, simple dashboard, PDF reports

#### **Audience 2: Business Staff (Secondary)**
- **Needs**: Order status, delivery assignments, inventory levels
- **Delivery**: Shared dashboard view, WhatsApp group updates

#### **Audience 3: External Stakeholders (Tertiary)**
- **KRA**: eTIMS-compliant invoices, sales reports
- **Bank**: Cash flow statements for loan applications
- **Suppliers**: Inventory needs forecasting

### **6.2 The n8n Multi-Output Workflow**

```
WORKFLOW: DATA_MultiPurposeExport
Trigger: Manual or monthly schedule
Steps:
1. Query monthly sales data
2. Branch 1: Generate KRA report (PDF)
3. Branch 2: Generate bank statement (Excel)
4. Branch 3: Generate supplier order forecast (CSV)
5. Branch 4: Update public business page (if opted in)
6. Store all in Supabase Storage with access links
7. Send WhatsApp message with download links
```

---

## **7. THE VISUALIZATION TECH STACK DECISION**

### **7.1 Options Analysis**

| Tool | Best For | Complexity | Cost | Your Fit |
|------|----------|------------|------|----------|
| **Supabase Dashboard** | Embedded real-time views | Low | Free | ✅ Perfect for MVP |
| **Retool** | Internal admin panels | Medium | $10+/user | ⚠️ Overkill for SMEs |
| **Metabase** | Self-service analytics | High | Open source | ⚠️ Too complex for users |
| **Custom React + Charts.js** | Branded customer-facing | High | Dev time | ❌ Not your focus |
| **n8n → WhatsApp** | Push-based intelligence | Low | Free | ✅ Your superpower |

### **7.2 Recommended Stack: The WhatsApp-First Intelligence**

```
PRIMARY CHANNEL: WhatsApp (80% of insights)
  - Daily summary at 8 AM
  - Low stock alerts immediately
  - ROAS alerts at 6 PM
  - Weekly report every Monday

SECONDARY CHANNEL: Simple Web Dashboard (20% deep dive)
  - Real-time order board
  - Product performance charts
  - Customer search
  - Export functionality

TERTIARY CHANNEL: Automated PDF Reports (for external)
  - Monthly for KRA
  - Quarterly for bank
  - On-demand for partners
```

### **7.3 Implementation Priority**

```
PHASE 1 (Week 1-2): WhatsApp Intelligence
  - Workflow: REPORT_DailyWhatsApp
  - Workflow: ALERT_StockWhatsApp
  - Workflow: ALERT_ROASWhatsApp

PHASE 2 (Week 3-4): Simple Web Dashboard
  - View: today_live_dashboard
  - View: product_performance
  - Feature: order search

PHASE 3 (Week 5-6): External Reporting
  - Workflow: REPORT_KRA_Monthly
  - Workflow: REPORT_Bank_Statement
  - Storage: Secure document storage
```

---

## **8. THE COMPLETE INTELLIGENCE ORCHESTRATION**

### **8.1 Daily Intelligence Flow**

```
6 AM: Data Aggregation
  ↓
n8n: ANALYTICS_Hourly
  ↓
Supabase: Update cache
  ↓
8 AM: Morning Report
  ↓
n8n: REPORT_DailyWhatsApp
  ↓
Owner: Gets WhatsApp summary

Real-time: Order Update
  ↓
Supabase: Realtime subscription
  ↓
Dashboard: Live update

6 PM: Evening Insights
  ↓
n8n: ANALYTICS_ROAS_Calculator
  ↓
WhatsApp: ROAS alerts

10 PM: Bookkeeping Close
  ↓
n8n: BOOKKEEPING_DailyClose
  ↓
Cashbook updated + Daily PDF stored
```

### **8.2 The "Good Enough" Metrics**

What makes bookkeeping "good enough" for Nairobi SMEs:

1. **Cash Position Accuracy**: Daily cash balance within ±KSh 500
2. **Invoice Generation Time**: < 30 seconds from order to KRA invoice
3. **Report Freshness**: Never more than 2 hours stale
4. **Search Recall**: Find any order from last 90 days in < 5 seconds
5. **Alert Relevance**: 0 false positives on stock alerts

---

## **9. THE RESEARCH MODE: DATA-DRIVEN FEATURES**

Once data flows, n8n enables **automatic research**:

### **9.1 Automated Customer Research**
```
WORKFLOW: RESEARCH_CustomerPatterns
Trigger: Weekly analysis
Finds:
- Best time to post Reels (based on conversion time)
- Optimal product pricing (price elasticity from data)
- Customer churn signals (order frequency dropping)
- Cross-sell opportunities (A products → B products)
```

### **9.2 Automated Market Research**
```
WORKFLOW: RESEARCH_MarketPosition
Trigger: Monthly analysis
Compares:
- Your SME's performance vs. industry benchmarks
- Price positioning vs. competitors (web scraped)
- Delivery time benchmarks
- Customer satisfaction trends
```

### **9.3 The Research Data Lake**

```sql
-- RESEARCH-SPECIFIC TABLES
CREATE TABLE research_findings (
  tenant_id UUID REFERENCES tenants(id),
  insight_type TEXT, -- 'customer', 'product', 'market'
  insight_text TEXT,
  confidence_score DECIMAL, -- 0-1 how sure we are
  data_points_used INT,
  generated_at TIMESTAMPTZ,
  action_recommendation TEXT
);

-- Example insights n8n can generate:
-- "Customers who buy Nike Air Max often also buy socks (65% correlation)"
-- "Reels posted at 7 PM convert 40% better than 2 PM posts"
-- "Increasing price of Product X by KSh 100 would reduce sales by 15% but increase profit by 22%"
```

---

## **10. THE ONE-PAGE SUMMARY**

### **Your Data Intelligence Stack:**

1. **Source**: Supabase (single source of truth)
2. **Transformer**: n8n workflows (hourly/daily aggregation)
3. **Delivery**: WhatsApp + Simple Dashboard + PDF exports
4. **Recall**: Full-text search + filtered views
5. **Research**: Automated insight generation via n8n

### **Your Competitive Data Advantage:**

While competitors show "data", you deliver **insights**:
- Not "24 orders today" but "KSh 42,000 revenue, 38% from Reel #452"
- Not "low stock alert" but "Order 24 more units, will sell out in 3 days"
- Not "monthly report" but "Here's your KRA submission ready PDF"

### **Immediate Action Plan:**

1. **Build** `ANALYTICS_Hourly` workflow today
2. **Build** `REPORT_DailyWhatsApp` workflow tomorrow
3. **Create** `today_live_dashboard` view in Supabase
4. **Test** with 1 pilot SME, iterate based on their actual usage

---

## **11. DATABASE MIGRATIONS FOR INTELLIGENCE SYSTEM**

### **11.1 Analytics Tables Migration**

```sql
-- File: apps/supabase/migrations/010_create_analytics_tables.sql

-- Analytics Daily Summary (Materialized View)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_daily_summary AS
SELECT 
  tenant_id,
  DATE(created_at) as date,
  COUNT(DISTINCT orders.id) as order_count,
  SUM(orders.total_amount) as revenue,
  COUNT(DISTINCT leads.id) as lead_count,
  ROUND(COUNT(DISTINCT orders.id)::decimal / NULLIF(COUNT(DISTINCT leads.id), 0) * 100, 2) as conversion_rate
FROM tenants
LEFT JOIN leads ON leads.tenant_id = tenants.id 
  AND DATE(leads.created_at) = CURRENT_DATE - INTERVAL '1 day'
LEFT JOIN orders ON orders.tenant_id = tenants.id 
  AND DATE(orders.created_at) = CURRENT_DATE - INTERVAL '1 day'
  AND orders.status = 'paid'
GROUP BY tenant_id, DATE(created_at);

-- Cashbook Table
CREATE TABLE IF NOT EXISTS cashbook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  transaction_date DATE NOT NULL,
  description TEXT,
  reference TEXT,
  amount DECIMAL(10,2) NOT NULL,
  type TEXT CHECK (type IN ('income', 'expense')),
  category TEXT,
  balance_after DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer RFM Scores
CREATE TABLE IF NOT EXISTS customer_rfm_scores (
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  customer_phone TEXT NOT NULL,
  recency_score INT,
  frequency_score INT,
  monetary_score INT,
  segment TEXT,
  last_calculated TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (tenant_id, customer_phone)
);

-- Research Findings
CREATE TABLE IF NOT EXISTS research_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  insight_type TEXT,
  insight_text TEXT,
  confidence_score DECIMAL(3,2),
  data_points_used INT,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  action_recommendation TEXT
);

-- Indexes
CREATE INDEX idx_cashbook_tenant_date ON cashbook(tenant_id, transaction_date DESC);
CREATE INDEX idx_research_tenant_type ON research_findings(tenant_id, insight_type);

-- RLS Policies
ALTER TABLE cashbook ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_rfm_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE research_findings ENABLE ROW LEVEL SECURITY;

CREATE POLICY cashbook_isolation ON cashbook
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));

CREATE POLICY rfm_isolation ON customer_rfm_scores
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));

CREATE POLICY research_isolation ON research_findings
  FOR ALL USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));
```

---

## **12. N8N WORKFLOW SPECIFICATIONS**

### **12.1 ANALYTICS_Hourly Workflow**

**File:** `apps/n8n/workflows/15_analytics_hourly.json`

**Purpose:** Pre-calculate hourly metrics for fast dashboard loading

**Steps:**
1. Query last hour's orders, leads, payments
2. Aggregate by tenant
3. Update `analytics_cache` table
4. Trigger realtime dashboard update

**Output:** Updated cache, WebSocket broadcast

### **12.2 REPORT_DailyWhatsApp Workflow**

**File:** `apps/n8n/workflows/16_report_daily_whatsapp.json`

**Purpose:** Send daily summary via WhatsApp at 8 AM

**Steps:**
1. Query yesterday's data from `analytics_daily_summary`
2. Query top 3 products
3. Query pending orders
4. Format message with emojis
5. Send via WhatsApp to business owner

**Output:** WhatsApp message with daily summary

### **12.3 BOOKKEEPING_DailyClose Workflow**

**File:** `apps/n8n/workflows/17_bookkeeping_daily_close.json`

**Purpose:** Close daily books and generate cash position

**Steps:**
1. Query today's paid orders → Insert as income
2. Query today's expenses (ad spend, delivery)
3. Calculate running balance
4. Generate PDF report
5. Store in Supabase Storage
6. Send WhatsApp summary

**Output:** Cashbook updated, PDF stored, WhatsApp alert

---

## **FINAL INSIGHT**

**THE FINAL INSIGHT**: 
Nairobi SMEs don't need "data visualization." 
They need **"what to do at 10 AM tomorrow"** delivered via WhatsApp.
Your n8n workflows turn data into **actionable commands**, not just pretty charts.

Build the WhatsApp intelligence first. The dashboard is optional. The insights are everything.

---

**Status: Production Ready**  
**Priority: Week 2-3 Implementation**  
**Impact: 80% of insights via WhatsApp, 20% via dashboard**

---

**End of DATA INTELLIGENCE SYSTEM DOCUMENT** ✅

