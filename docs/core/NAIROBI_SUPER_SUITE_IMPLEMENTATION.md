# Nairobi Super Suite - Implementation Plan
**Based on:** `NAIROBI_SUPER_SUITE_EXPANSION.md`  
**Date:** January 9, 2026  
**Status:** Planning Phase

---

## 🎯 Executive Summary

**Goal:** Build complete Instagram Reels → WhatsApp Orders → M-Pesa Payments → Analytics pipeline

**Current State:**
- ✅ WhatsApp workflows (12 workflows ready)
- ✅ M-Pesa integration (Daraja sandbox configured)
- ✅ Supabase database (multi-tenant, RLS enabled)
- ✅ n8n orchestration (Docker setup ready)
- ❌ **Instagram integration (NEW - needs to be built)**
- ❌ **Instagram attribution tracking (NEW)**
- ❌ **Analytics dashboard (NEW)**

**Target Timeline:** 4 weeks to production (per expansion plan)

---

## 📊 Gap Analysis: What's Built vs What's Needed

### ✅ Already Built (No Changes Needed)

1. **WhatsApp Integration**
   - ✅ Meta WhatsApp Cloud API configured
   - ✅ Message classification workflow (`01_classify_message_v2.json`)
   - ✅ Send WhatsApp workflow (`03_send_whatsapp_v2.json`)
   - ✅ SMS fallback (`04_send_sms_fallback_v2.json`)
   - ✅ Payment confirmation (`07_send_payment_confirmation_v2.json`)

2. **M-Pesa Integration**
   - ✅ Daraja API configured (sandbox)
   - ✅ Payment reconciliation (`06_reconcile_payment_v2.json`)
   - ✅ STK Push workflow (in reconciliation workflow)
   - ✅ Webhook signature verification (code ready)

3. **Database**
   - ✅ Multi-tenant schema (tenants, tenant_config)
   - ✅ Orders table (with source field)
   - ✅ Payments table (with reconciliation logic)
   - ✅ Messages table (conversation history)
   - ✅ RLS policies (tenant isolation)

4. **Infrastructure**
   - ✅ n8n Docker setup
   - ✅ Environment variable management
   - ✅ Health check scripts
   - ✅ Error handling patterns

### 🆕 New Features to Build

#### Week 1: Instagram Lead Gen (MVP)

1. **Instagram Comment Trigger Workflow** ⭐ CRITICAL
   - Webhook receiver for Instagram comments
   - Keyword detection ("DM", "Price", "YES")
   - Phone number extraction (from bio/followers)
   - Lead record creation in Supabase
   - Auto-DM via WhatsApp

2. **Database Schema Updates**
   - `leads` table (if not exists)
     - `id`, `tenant_id`, `source` (instagram), `instagram_user_id`, `phone`, `reel_id`, `comment_text`, `status`, `created_at`
   - `instagram_media` table (for Reels tracking)
     - `id`, `tenant_id`, `media_id`, `media_type`, `caption`, `permalink`, `timestamp`, `insights` (JSONB)

3. **Meta Business API Setup**
   - Instagram Graph API credentials
   - Webhook subscription (comments, mentions)
   - OAuth token management

#### Week 2: Attribution + Advanced Features

4. **Meta Ads Attribution**
   - Campaign spend tracking
   - Lead → Order → Revenue mapping
   - ROAS calculation

5. **WhatsApp Flows Integration**
   - Order form (native WhatsApp forms)
   - Product selection
   - Delivery address collection

6. **Voice/Image Parsing** (Already has foundation)
   - Enhance existing `media-processing.json` workflow
   - Add Sheng/Somali language detection
   - Improve accuracy for Kenyan context

#### Week 3-4: Marketing Automation + Hardening

7. **Abandoned Cart Recovery**
   - Detection logic (order created, not paid)
   - WhatsApp reminder sequences
   - A/B testing framework

8. **Analytics Dashboard**
   - Basic metrics (leads, orders, revenue)
   - Instagram attribution (ROAS)
   - Funnel visualization
   - Reels performance tracking

9. **Production Hardening**
   - M-Pesa signature verification (critical)
   - Monitoring & alerting
   - Load testing
   - KRA eTIMS integration (Week 9+)

---

## 🚀 Implementation Roadmap

### Phase 1: Instagram Lead Gen (Week 1, Days 1-3)

#### Day 1: Meta Instagram API Setup

**Tasks:**
1. Create Instagram Business Account (if needed)
2. Connect Instagram account to Meta Business Manager
3. Get Instagram Graph API credentials:
   - `INSTAGRAM_BUSINESS_ACCOUNT_ID`
   - `INSTAGRAM_ACCESS_TOKEN` (or use Meta Business unified token)
4. Test Instagram API connection
5. Add credentials to `.env` file

**Deliverables:**
- ✅ Instagram API credentials configured
- ✅ Test API call successful (GET /{ig_user_id}/media)

#### Day 2: Instagram Comment Webhook

**Tasks:**
1. Create n8n workflow: `13_instagram_comment_trigger.json`
   - Webhook trigger (POST /webhook/instagram-comments)
   - Parse comment payload
   - Extract: comment text, user ID, media ID, timestamp
   - Keyword detection ("DM", "Price", "YES", "Interested")
   - Phone extraction logic (from bio or followers API)
2. Create lead record in Supabase
3. Trigger WhatsApp auto-DM workflow
4. Test with real Instagram comment

**Database Migration:**
```sql
-- Create leads table (if not exists)
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  source TEXT NOT NULL DEFAULT 'instagram',
  instagram_user_id TEXT,
  phone TEXT,
  reel_id TEXT,
  comment_text TEXT,
  status TEXT DEFAULT 'new', -- new, contacted, converted, lost
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY leads_isolation ON leads
  FOR ALL
  USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));
```

**Deliverables:**
- ✅ Instagram comment webhook workflow
- ✅ Leads table created
- ✅ Test: Comment on Reel → Lead created → WhatsApp DM sent

#### Day 3: Phone Extraction + WhatsApp Handoff

**Tasks:**
1. Enhance Instagram workflow:
   - Fetch user bio (GET /{ig_user_id})
   - Extract phone from bio (regex patterns)
   - Fallback: Check followers (if permission granted)
   - Create WhatsApp contact if phone found
2. Integrate with existing WhatsApp catalog workflow
3. End-to-end test: Instagram comment → WhatsApp catalog → Order

**Deliverables:**
- ✅ Phone extraction working (80%+ accuracy)
- ✅ Instagram → WhatsApp handoff complete
- ✅ End-to-end flow tested

---

### Phase 2: Attribution + Analytics (Week 2)

#### Day 4-5: Meta Ads Attribution

**Tasks:**
1. Create workflow: `14_meta_ads_attribution.json`
   - Fetch campaign data (GET /act_{ad_account_id}/campaigns)
   - Track ad spend per campaign
   - Map campaign → lead → order → revenue
   - Calculate ROAS (Revenue / Ad Spend)
2. Create `campaigns` table in Supabase
3. Create `attribution` table (campaign → lead → order mapping)
4. Update analytics queries to include ROAS

**Database Schema:**
```sql
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  campaign_id TEXT NOT NULL, -- Meta campaign ID
  campaign_name TEXT,
  ad_account_id TEXT,
  spend_kes DECIMAL(10,2),
  impressions INTEGER,
  clicks INTEGER,
  leads_count INTEGER,
  orders_count INTEGER,
  revenue_kes DECIMAL(10,2),
  roas DECIMAL(5,2), -- revenue / spend
  date_range_start DATE,
  date_range_end DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  campaign_id TEXT,
  lead_id UUID REFERENCES leads(id),
  order_id UUID REFERENCES orders(id),
  attribution_type TEXT, -- view, click, conversion
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Deliverables:**
- ✅ Campaign tracking workflow
- ✅ ROAS calculation working
- ✅ Attribution data stored

#### Day 6-7: Reels Performance Tracking

**Tasks:**
1. Create workflow: `15_reels_performance_tracking.json`
   - Fetch Reels insights (GET /{ig_media_id}/insights)
   - Track: views, saves, shares, comments, reach
   - Store in `instagram_media` table
2. Create analytics query: Top performing Reels
3. Add Reels performance card to dashboard

**Deliverables:**
- ✅ Reels insights tracking
- ✅ Performance metrics stored
- ✅ Top Reels query working

---

### Phase 3: Advanced Features (Week 3-4)

#### Abandoned Cart Recovery (Week 3)

**Tasks:**
1. Create workflow: `16_abandoned_cart_recovery.json`
   - Scheduled trigger (every hour)
   - Query: Orders created > 1hr ago, status = 'pending', no payment
   - Send WhatsApp reminder (1hr, 4hr, next day)
   - A/B test message variants
2. Create `abandoned_carts` table for tracking
3. Recovery rate analytics

#### Analytics Dashboard (Week 4)

**Tasks:**
1. Create Supabase Edge Function or n8n scheduled workflow
2. Aggregate metrics:
   - Leads captured (by source: Instagram)
   - Orders created (by source)
   - Revenue (paid orders)
   - ROAS (by campaign)
   - Conversion funnel (Reels → WhatsApp → Order → Paid)
3. Create simple dashboard (HTML/React or Supabase dashboard)
4. Real-time updates (optional: WebSockets)

---

## 📋 Implementation Checklist

### Week 1: Instagram Lead Gen (MVP)
- [ ] Day 1: Meta Instagram API setup
  - [ ] Instagram Business Account created
  - [ ] API credentials obtained
  - [ ] Test API connection
- [ ] Day 2: Instagram comment webhook
  - [ ] Create `13_instagram_comment_trigger.json` workflow
  - [ ] Create `leads` table migration
  - [ ] Test comment → lead creation
- [ ] Day 3: Phone extraction + WhatsApp handoff
  - [ ] Phone extraction logic
  - [ ] WhatsApp auto-DM integration
  - [ ] End-to-end test

### Week 2: Attribution + Analytics
- [ ] Meta Ads attribution workflow
- [ ] Campaigns & attribution tables
- [ ] ROAS calculation
- [ ] Reels performance tracking
- [ ] Top Reels analytics

### Week 3: Marketing Automation
- [ ] Abandoned cart recovery
- [ ] A/B testing framework
- [ ] Recovery rate tracking

### Week 4: Dashboard + Hardening
- [ ] Analytics dashboard
- [ ] Funnel visualization
- [ ] Production hardening
- [ ] Load testing

---

## 🔧 Technical Implementation Details

### Instagram Comment Webhook Payload Structure

```json
{
  "object": "instagram",
  "entry": [{
    "id": "instagram_page_id",
    "time": 1234567890,
    "messaging": [{
      "sender": {
        "id": "instagram_user_id"
      },
      "recipient": {
        "id": "instagram_page_id"
      },
      "timestamp": 1234567890,
      "comment": {
        "id": "comment_id",
        "text": "DM me the price",
        "media": {
          "id": "media_id",
          "type": "REELS"
        }
      }
    }]
  }]
}
```

### n8n Workflow Structure: Instagram Comment Trigger

```
Instagram Webhook
  ↓
Parse Comment Payload
  ↓
Extract: user_id, media_id, comment_text
  ↓
Keyword Detection ("DM", "Price", "YES")
  ↓
Fetch Instagram User Bio
  ↓
Extract Phone from Bio
  ↓
Create Lead Record (Supabase)
  ↓
Trigger WhatsApp Auto-DM
  ↓
Send Catalog Message
```

### Environment Variables to Add

```bash
# Instagram Graph API
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_ig_business_account_id
INSTAGRAM_ACCESS_TOKEN=your_ig_access_token  # Or use META_ACCESS_TOKEN if unified

# Meta Ads (for attribution)
META_AD_ACCOUNT_ID=act_123456789
META_APP_ID=your_meta_app_id
```

---

## 🧪 Testing Strategy

### Unit Tests
1. Phone extraction regex patterns
2. Keyword detection logic
3. Lead creation validation
4. Attribution mapping

### Integration Tests
1. Instagram comment → Lead created
2. Lead → WhatsApp DM sent
3. Campaign → Lead → Order → Revenue mapping
4. Payment reconciliation with attribution

### End-to-End Tests
1. User comments on Reel → Receives WhatsApp catalog → Places order → Pays → Confirmed
2. Campaign attribution: Ad spend → Leads → Orders → Revenue → ROAS calculated

---

## 📚 Reference Documentation

### Meta APIs
- Instagram Graph API: https://developers.facebook.com/docs/instagram-api
- Meta Marketing API: https://developers.facebook.com/docs/marketing-api
- Meta Business API: https://developers.facebook.com/docs/business-manager-api

### n8n Nodes
- Meta Business: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.metabusiness
- HTTP Request: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest
- Webhook: https://docs.n8n.io/integrations/builtin/trigger-nodes/n8n-nodes-base.webhook

---

## 🎯 Success Metrics

**Week 1:**
- ✅ Instagram comment webhook receiving events
- ✅ Leads table populated with test data
- ✅ WhatsApp auto-DM working
- ✅ End-to-end flow tested

**Week 2:**
- ✅ Campaign attribution tracking
- ✅ ROAS calculation accurate
- ✅ Reels performance data collected

**Week 4:**
- ✅ Analytics dashboard showing metrics
- ✅ Production-ready (security hardened)
- ✅ Ready for 5-10 early adopter customers

---

## 🚨 Critical Dependencies

1. **Meta Business Account** - Required for Instagram API access
2. **Instagram Business Profile** - Must convert personal to business
3. **Meta App Review** - May need app review for production webhooks
4. **Instagram Permissions** - Need `instagram_basic`, `instagram_manage_comments`, `pages_read_engagement`

---

**Next Step:** Start with Day 1 tasks (Meta Instagram API setup)

