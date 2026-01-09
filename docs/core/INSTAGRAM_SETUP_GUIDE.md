# Instagram Integration Setup Guide
**Nairobi Super Suite: Week 1 Core Engine**  
**Instagram Reels → WhatsApp Orders → M-Pesa Payments**

---

## 🎯 Overview

This guide walks you through setting up the Instagram comment trigger workflow that powers the core revenue pipeline:

**Instagram Comment** → **Lead Created** → **WhatsApp Auto-DM** → **Order** → **M-Pesa Payment**

---

## ✅ Prerequisites

- ✅ Meta Business Account
- ✅ Instagram Business Account (connected to Meta Business)
- ✅ WhatsApp Business API configured (already done)
- ✅ Supabase database (already set up)
- ✅ n8n running (Docker setup ready)

---

## 📋 Step-by-Step Setup

### Step 1: Meta Instagram API Setup (30-45 mins)

#### 1.1 Create/Configure Meta App

1. Go to https://developers.facebook.com
2. Select your existing Meta App (or create new one)
3. Add **Instagram Product**:
   - Go to **Add Product** → **Instagram**
   - Click **Set Up** on Instagram Graph API

#### 1.2 Connect Instagram Business Account

1. Go to **Instagram** → **Basic Display** or **Graph API**
2. Add Instagram Business Account:
   - Go to **Settings** → **Basic**
   - Add Instagram Business Account
   - Follow OAuth flow to connect your Instagram account

#### 1.3 Get Instagram Business Account ID

1. Go to **Instagram** → **Basic Display** → **User Token Generator**
2. Or use Graph API Explorer:
   ```
   GET /me/accounts
   ```
   This returns your Instagram Business Account ID

#### 1.4 Get Access Token

**Option A: Use Unified Meta Business Token (Recommended)**
- If you already have `META_ACCESS_TOKEN` for WhatsApp, you can use the same token
- Instagram Graph API uses the same Meta Business API

**Option B: Generate Instagram-Specific Token**
1. Go to **Tools** → **Graph API Explorer**
2. Select your app
3. Select **Instagram Graph API** permissions:
   - `instagram_basic`
   - `instagram_manage_comments`
   - `pages_read_engagement`
   - `pages_show_list`
4. Generate token

#### 1.5 Test API Connection

```bash
# Test Instagram API
curl -X GET "https://graph.facebook.com/v18.0/{ig_user_id}/media?access_token={token}"

# Should return your Instagram media (posts, reels)
```

#### 1.6 Add to Environment Variables

Add to your `.env` file:

```bash
# Instagram Graph API
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_ig_business_account_id
INSTAGRAM_ACCESS_TOKEN=your_ig_access_token
# Or use existing META_ACCESS_TOKEN if unified
```

**Note:** If using unified Meta Business API, you can use `META_ACCESS_TOKEN` for both WhatsApp and Instagram.

---

### Step 2: Database Migration (5 mins)

#### 2.1 Run Migration

```bash
# In Supabase SQL Editor or via MCP
# Run migration: apps/supabase/migrations/009_create_leads_table.sql
```

Or use Supabase MCP:

```sql
-- Copy contents of 009_create_leads_table.sql and run in Supabase
```

#### 2.2 Verify Table Created

```sql
-- Check table exists
SELECT * FROM leads LIMIT 1;

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'leads';
-- Should show: rowsecurity = true
```

---

### Step 3: Import n8n Workflow (10 mins)

#### 3.1 Import Workflow

1. Open n8n: http://localhost:5678
2. Go to **Workflows** → **Import from File**
3. Select: `apps/n8n/workflows/13_instagram_comment_trigger.json`
4. Review workflow nodes (they're pre-configured)

#### 3.2 Configure Environment Variables in n8n

Go to **Settings** → **Environment Variables** and add:

```bash
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_ig_business_account_id
INSTAGRAM_ACCESS_TOKEN=your_ig_access_token
# Or use META_ACCESS_TOKEN if unified
```

**Note:** The workflow uses `{{ $env.INSTAGRAM_ACCESS_TOKEN || $env.META_ACCESS_TOKEN }}` so it will use either.

#### 3.3 Activate Workflow

1. Toggle **Active** switch in workflow (top right)
2. Copy the webhook URL (shown in webhook node)

---

### Step 4: Configure Meta Webhook (15 mins)

#### 4.1 Get Webhook URL

From n8n workflow `13_instagram_comment_trigger`:
- Webhook URL: `http://localhost:5678/webhook/instagram-comments`
- For production: Use ngrok or your public URL

**For Local Testing (ngrok):**
```bash
# Start ngrok
ngrok http 5678

# Copy HTTPS URL (e.g., https://abc123.ngrok.io)
# Webhook URL: https://abc123.ngrok.io/webhook/instagram-comments?tenant_id=sme_001
```

#### 4.2 Configure in Meta App Dashboard

1. Go to https://developers.facebook.com
2. Select your app → **Instagram** → **Webhooks**
3. Click **Add Webhook** or **Edit** existing
4. Configure:
   - **Callback URL:** `https://your-n8n-url.com/webhook/instagram-comments?tenant_id=sme_001`
   - **Verify Token:** (same as `VERIFY_TOKEN` in your `.env`)
   - Click **Verify and Save**
5. **Subscribe to Events:**
   - ✅ `comments` (comment on media)
   - ✅ `mentions` (mention in comment)
   - Click **Save**

#### 4.3 Test Webhook

1. Comment on your test Instagram Reel: **"DM me the price"**
2. Check n8n **Executions** tab:
   - Should see webhook received
   - Should see workflow execution
3. Check Supabase `leads` table:
   ```sql
   SELECT * FROM leads ORDER BY created_at DESC LIMIT 1;
   ```
   - Should see new lead record

---

### Step 5: Test End-to-End Flow (15 mins)

#### 5.1 Test Instagram Comment → Lead

1. Comment on test Reel: **"DM me"** or **"Price?"**
2. Verify:
   - ✅ Webhook received in n8n
   - ✅ Lead created in Supabase
   - ✅ Phone extracted (if in bio)

#### 5.2 Test WhatsApp Auto-DM

1. Ensure phone number is in Instagram bio (for testing)
2. Comment: **"DM me the price"**
3. Verify:
   - ✅ Lead created
   - ✅ WhatsApp message sent (check your WhatsApp Business number)
   - ✅ Catalog message received

#### 5.3 Test Full Flow

1. Instagram comment → Lead created ✅
2. WhatsApp catalog sent ✅
3. Customer places order via WhatsApp ✅
4. M-Pesa payment completed ✅
5. Order confirmed ✅

---

## 🔧 Troubleshooting

### Webhook Not Receiving Events

**Check:**
- ✅ Webhook URL is correct in Meta dashboard
- ✅ Verify token matches in both places
- ✅ Workflow is activated in n8n
- ✅ ngrok is running (for local testing)
- ✅ Check n8n Executions tab for errors

**Debug:**
```bash
# Check n8n logs
docker-compose logs -f n8n

# Check webhook signature (should be verified)
# Look for "signature_verified: true" in execution data
```

### Phone Not Extracted

**Check:**
- ✅ Instagram user has phone in bio
- ✅ Phone format is correct (+254, 07, 254)
- ✅ Check execution data: `phone_extracted: true/false`

**Manual Test:**
```javascript
// Test phone extraction regex
const bio = "Contact: +254712345678";
const pattern = /\+254\d{9}/g;
const match = bio.match(pattern);
console.log(match); // Should return: ["+254712345678"]
```

### Lead Not Created

**Check:**
- ✅ Supabase connection (test in n8n)
- ✅ RLS policies (check tenant_id)
- ✅ Migration ran successfully
- ✅ Check error logs in n8n Executions

**Debug:**
```sql
-- Check if lead was created
SELECT * FROM leads WHERE comment_id = 'your_comment_id';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'leads';
```

### WhatsApp DM Not Sent

**Check:**
- ✅ Phone number is valid
- ✅ WhatsApp workflow (`03_send_whatsapp_v2`) is activated
- ✅ WhatsApp credentials are configured
- ✅ Check execution of `03_send_whatsapp_v2` workflow

**Debug:**
- Check n8n Executions for `03_send_whatsapp_v2`
- Verify phone format: `+254712345678`
- Check WhatsApp API response in execution data

---

## 🔒 Security Checklist

Before going to production:

- [ ] **Webhook Signature Verification**
  - ✅ Already implemented in workflow
  - ✅ Uses `WHATSAPP_APP_SECRET` or `META_APP_SECRET`
  - ✅ Rejects invalid signatures (401)

- [ ] **RLS Policies**
  - ✅ `leads` table has RLS enabled
  - ✅ Tenant isolation policy created
  - ✅ Test with different tenant_ids

- [ ] **Environment Variables**
  - ✅ `INSTAGRAM_ACCESS_TOKEN` or `META_ACCESS_TOKEN` set
  - ✅ `WHATSAPP_APP_SECRET` or `META_APP_SECRET` set (for signature verification)
  - ✅ `SUPABASE_SERVICE_ROLE_KEY` set

- [ ] **Production Webhook URL**
  - ✅ Use HTTPS (not HTTP)
  - ✅ Use production domain (not ngrok)
  - ✅ Verify token is secure (random string)

---

## 📊 Monitoring

### Key Metrics to Track

1. **Lead Conversion Rate**
   ```sql
   SELECT 
     COUNT(*) as total_leads,
     COUNT(CASE WHEN converted_to_order THEN 1 END) as converted,
     ROUND(100.0 * COUNT(CASE WHEN converted_to_order THEN 1 END) / COUNT(*), 2) as conversion_rate
   FROM leads
   WHERE created_at >= NOW() - INTERVAL '7 days';
   ```

2. **Phone Extraction Rate**
   ```sql
   SELECT 
     COUNT(*) as total_leads,
     COUNT(CASE WHEN phone IS NOT NULL THEN 1 END) as with_phone,
     ROUND(100.0 * COUNT(CASE WHEN phone IS NOT NULL THEN 1 END) / COUNT(*), 2) as extraction_rate
   FROM leads
   WHERE created_at >= NOW() - INTERVAL '7 days';
   ```

3. **Top Performing Reels**
   ```sql
   SELECT 
     reel_id,
     reel_permalink,
     COUNT(*) as leads_count,
     COUNT(CASE WHEN converted_to_order THEN 1 END) as conversions
   FROM leads
   WHERE reel_id IS NOT NULL
   GROUP BY reel_id, reel_permalink
   ORDER BY leads_count DESC
   LIMIT 10;
   ```

---

## 🎯 Next Steps

After Instagram setup is complete:

1. **Week 2:** Meta Ads Attribution
   - Track campaign spend
   - Calculate ROAS
   - Map Campaign → Lead → Order → Revenue

2. **Week 2:** Reels Performance Tracking
   - Fetch Reels insights
   - Track views, saves, shares
   - Identify top-performing Reels

3. **Week 3:** Abandoned Cart Recovery
   - Detect abandoned orders
   - Send WhatsApp reminders
   - A/B test messages

4. **Week 4:** Analytics Dashboard
   - Build dashboard with all metrics
   - Real-time updates
   - Funnel visualization

---

## 📚 Reference

- **Implementation Plan:** `docs/core/NAIROBI_SUPER_SUITE_IMPLEMENTATION.md`
- **Expansion Blueprint:** `docs/core/NAIROBI_SUPER_SUITE_EXPANSION.md`
- **Meta Instagram API:** https://developers.facebook.com/docs/instagram-api
- **Instagram Webhooks:** https://developers.facebook.com/docs/instagram-api/guides/webhooks
- **n8n Meta Business Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.metabusiness

---

**Ready to launch Week 1 MVP!** 🚀

