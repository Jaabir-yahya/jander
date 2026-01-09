# Nairobi Super Suite - Quick Start Guide
**For:** Implementing Instagram → WhatsApp → M-Pesa pipeline  
**Time:** 4 weeks to production  
**Status:** Ready to start Week 1

---

## 🎯 What You're Building

**Nairobi Super Suite** = Instagram Reels → WhatsApp Orders → M-Pesa Payments → Analytics

**Target:** Nairobi SMEs spending KSh 5K-50K/month on Instagram ads  
**Pricing:** KSh 1,499/month (freemium: 100 leads/month)  
**Week 12 Target:** KSh 50K MRR (33 customers)

---

## ✅ What's Already Done

- ✅ WhatsApp workflows (12 workflows ready to import)
- ✅ M-Pesa Daraja integration (sandbox configured)
- ✅ Supabase database (multi-tenant, RLS enabled)
- ✅ n8n Docker setup (ready to start)
- ✅ Error handling & retry logic
- ✅ Payment reconciliation workflow

---

## 🆕 What Needs to Be Built

### Week 1: Instagram Lead Gen (MVP) ⭐ START HERE

**Goal:** Instagram comment → WhatsApp DM → Order → Payment

#### Day 1: Meta Instagram API Setup (2-3 hours)

**Steps:**
1. Go to https://developers.facebook.com
2. Create/select Meta App
3. Add Instagram Product
4. Get Instagram Business Account ID
5. Get Access Token (or use unified Meta Business token)
6. Test API: `GET https://graph.facebook.com/v18.0/{ig_user_id}/media`

**Add to `.env`:**
```bash
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_ig_business_account_id
INSTAGRAM_ACCESS_TOKEN=your_ig_access_token
# Or use existing META_ACCESS_TOKEN if unified
```

**Test:**
```bash
curl -X GET "https://graph.facebook.com/v18.0/{ig_user_id}/media?access_token={token}"
```

#### Day 2: Instagram Comment Webhook (4-6 hours)

**Create Workflow:** `apps/n8n/workflows/13_instagram_comment_trigger.json`

**Workflow Structure:**
```
Webhook Trigger (POST /webhook/instagram-comments)
  ↓
Parse Comment Payload
  ↓
Extract: user_id, media_id, comment_text
  ↓
Keyword Detection ("DM", "Price", "YES", "Interested")
  ↓
Fetch Instagram User Bio (GET /{ig_user_id})
  ↓
Extract Phone from Bio (regex)
  ↓
Create Lead Record (Supabase INSERT)
  ↓
Trigger WhatsApp Auto-DM (call existing workflow)
```

**Database Migration:**
Create `apps/supabase/migrations/009_create_leads_table.sql`:
```sql
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  source TEXT NOT NULL DEFAULT 'instagram',
  instagram_user_id TEXT,
  phone TEXT,
  reel_id TEXT,
  comment_text TEXT,
  status TEXT DEFAULT 'new',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY leads_isolation ON leads
  FOR ALL
  USING (tenant_id IN (
    SELECT id FROM tenants WHERE id = auth.uid() OR id IN (
      SELECT tenant_uuid FROM tenant_config WHERE tenant_id = current_setting('app.tenant_id', true)
    )
  ));

CREATE INDEX idx_leads_tenant_id ON leads(tenant_id);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_status ON leads(status);
```

**Configure Webhook in Meta Dashboard:**
1. Go to Meta App Dashboard → Instagram → Webhooks
2. Add webhook: `https://your-n8n-url.com/webhook/instagram-comments?tenant_id=sme_001`
3. Subscribe to: `comments`, `mentions`
4. Verify token matches `VERIFY_TOKEN` in `.env`

#### Day 3: Phone Extraction + WhatsApp Handoff (4-6 hours)

**Enhance Workflow:**
1. Add phone extraction logic:
   - Regex patterns: `+254\d{9}`, `07\d{8}`, `254\d{9}`
   - Check Instagram bio first
   - Fallback: Check followers (if permission granted)
2. Integrate with existing WhatsApp workflow:
   - Call `03_send_whatsapp_v2.json` workflow
   - Send catalog message
   - Track in conversation history

**Test End-to-End:**
1. Comment on test Reel: "DM me the price"
2. Verify lead created in Supabase
3. Verify WhatsApp DM sent with catalog
4. Place test order via WhatsApp
5. Complete M-Pesa payment
6. Verify order confirmed

---

### Week 2: Attribution + Analytics

#### Meta Ads Attribution (Days 4-5)

**Create Workflow:** `14_meta_ads_attribution.json`

**Tasks:**
1. Fetch campaigns: `GET /act_{ad_account_id}/campaigns`
2. Track ad spend per campaign
3. Map: Campaign → Lead → Order → Revenue
4. Calculate ROAS = Revenue / Ad Spend

**Database:**
- `campaigns` table (campaign data, spend, ROAS)
- `attribution` table (campaign → lead → order mapping)

#### Reels Performance (Days 6-7)

**Create Workflow:** `15_reels_performance_tracking.json`

**Tasks:**
1. Fetch Reels insights: `GET /{ig_media_id}/insights`
2. Track: views, saves, shares, comments, reach
3. Store in `instagram_media` table
4. Create analytics query: Top performing Reels

---

### Week 3-4: Advanced Features

- Abandoned cart recovery
- Analytics dashboard
- Production hardening
- KRA eTIMS integration (Week 9+)

---

## 🚀 Getting Started (Right Now)

### Step 1: Review Current State (15 mins)
```bash
# Check what workflows exist
ls apps/n8n/workflows/

# Check database migrations
ls apps/supabase/migrations/

# Review implementation plan
cat docs/core/NAIROBI_SUPER_SUITE_IMPLEMENTATION.md
```

### Step 2: Set Up Instagram API (Day 1 Task)
1. Go to https://developers.facebook.com
2. Create/select app
3. Add Instagram product
4. Get credentials
5. Add to `.env`

### Step 3: Create First Workflow (Day 2 Task)
1. Create `13_instagram_comment_trigger.json` in n8n
2. Set up webhook trigger
3. Add comment parsing logic
4. Test with real comment

### Step 4: Database Migration (Day 2 Task)
1. Create `009_create_leads_table.sql`
2. Run migration in Supabase
3. Verify table created

---

## 📋 Week 1 Checklist

- [ ] **Day 1:** Meta Instagram API setup
  - [ ] Instagram Business Account connected
  - [ ] API credentials obtained
  - [ ] Test API call successful
  - [ ] Credentials added to `.env`

- [ ] **Day 2:** Instagram comment webhook
  - [ ] Workflow `13_instagram_comment_trigger.json` created
  - [ ] Migration `009_create_leads_table.sql` created
  - [ ] Webhook configured in Meta dashboard
  - [ ] Test comment → lead creation

- [ ] **Day 3:** Phone extraction + WhatsApp handoff
  - [ ] Phone extraction logic implemented
  - [ ] WhatsApp auto-DM integrated
  - [ ] End-to-end flow tested
  - [ ] Ready for early adopters

---

## 🧪 Testing

### Quick Test (5 mins)
1. Comment on your test Reel: "DM me"
2. Check n8n Executions tab → Should see webhook received
3. Check Supabase `leads` table → Should see new lead
4. Check WhatsApp → Should receive catalog message

### Full Test (15 mins)
1. Instagram comment → Lead created ✅
2. WhatsApp catalog sent ✅
3. Order placed via WhatsApp ✅
4. M-Pesa payment completed ✅
5. Order confirmed ✅

---

## 📚 Key Resources

- **Implementation Plan:** `docs/core/NAIROBI_SUPER_SUITE_IMPLEMENTATION.md`
- **Expansion Blueprint:** `docs/core/NAIROBI_SUPER_SUITE_EXPANSION.md`
- **Meta Instagram API:** https://developers.facebook.com/docs/instagram-api
- **n8n Meta Business Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.metabusiness

---

## 🎯 Success Criteria (Week 1)

✅ Instagram comment webhook receiving events  
✅ Leads table populated  
✅ WhatsApp auto-DM working  
✅ End-to-end flow tested  
✅ Ready for 5-10 early adopter customers

---

**Ready to start? Begin with Day 1: Meta Instagram API Setup** 🚀

