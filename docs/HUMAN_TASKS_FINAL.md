# Human Tasks Checklist - Final Setup Guide

**Date:** January 9, 2026  
**Status:** ✅ Supabase & Meta WhatsApp Done - Need M-Pesa Sandbox  
**Estimated Time:** 1-2 hours (mostly M-Pesa setup + testing)

---

## ✅ What's Already Done

### Infrastructure & Database
- ✅ **Supabase:** Connected and configured
  - Project URL: `https://dbnlsdxmmdoufzhkrdtd.supabase.co`
  - All 8 migrations applied successfully
  - All tables created with Row-Level Security (RLS) enabled
  - Functions created: payment matching, tenant lookup
  - Test data seeded (3 test tenants)

### Code & Scripts
- ✅ **Environment Template:** `.sample.env` file with all required variables documented
- ✅ **Health Check Script:** `scripts/health-check.js` - validates all services
- ✅ **Environment Validation:** `scripts/validate-env.js` - validates all env vars
- ✅ **Webhook Servers:** WhatsApp and M-Pesa webhook receivers implemented
- ✅ **Code Cleanup:** SMSLeopard removed, Meta WhatsApp configured throughout

### External Services Setup
- ✅ **Supabase:** Service Role Key obtained and ready
- ✅ **Meta WhatsApp Business API:** Already configured
  - Access Token and Phone Number ID obtained
  - App Secret obtained (add to `.env` as `WHATSAPP_APP_SECRET`)
  - Ready to use in workflows

### n8n Workflows (All Created - Ready to Import)
- ✅ **12 workflows created** in `apps/n8n/workflows/`:
  - `00_lookup_tenant_config.json` - Tenant config lookup utility
  - `01_classify_message_v2.json` - Message classification (Meta WhatsApp)
  - `02_check_consent.json` - Consent validation
  - `03_send_whatsapp_v2.json` - Send WhatsApp messages (Meta API)
  - `04_send_sms_fallback_v2.json` - SMS fallback (local/AfricasTalking)
  - `05_log_message.json` - Message logging
  - `06_reconcile_payment_v2.json` - Payment reconciliation
  - `07_send_payment_confirmation_v2.json` - Payment confirmation
  - `08_submit_to_etims.json` - KRA eTIMS submission
  - `09_multi_rail_payment.json` - Multi-rail payment routing
  - `10_handle_order_with_confirmation.json` - Order confirmation flow
  - `11_reorder_bot.json` - Reorder automation
  - `12_status_broadcast.json` - Status broadcast

### Docker Setup
- ✅ **n8n Docker:** `docker-compose.yml` configured and ready
- ✅ **Docker Scripts:** `docker-run.sh` available
- ✅ **Documentation:** `DOCKER_SETUP.md` with complete setup guide

**What You Still Need:** Credentials, `.env` file creation, starting n8n, and importing workflows

---

## 🚨 CRITICAL: What You Need to Do Now

### 1. ✅ Meta WhatsApp Business API Setup - **ALREADY DONE**

**Status:** ✅ Configured and ready

**Credentials you have:**
- ✅ Access Token: `WHATSAPP_ACCESS_TOKEN`
- ✅ Phone Number ID: `PHONE_NUMBER_ID`
- ✅ App Secret: `WHATSAPP_APP_SECRET` (add to `.env`)

**After n8n is running:**
- [ ] Configure webhook URL in Meta App Dashboard (if not already done):
  - Settings → WhatsApp → Configuration
  - Webhook URL: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
  - Verify Token: (same as `VERIFY_TOKEN` in .env)
  - Subscribe to: `messages`, `message_status`

---

### 2. ✅ Supabase Service Role Key - **ALREADY DONE**

**Status:** ✅ Service Role Key obtained

**Add to `.env`:**
- `SUPABASE_SERVICE_ROLE_KEY` = (your existing service role key)

---

### 3. M-Pesa Daraja Setup (30-60 minutes) ⭐ **REQUIRED**

**Important:** Start with **Sandbox** for testing. Production credentials come later via "Go Live" process.

#### Sandbox Setup (For Testing - Do This First)

**Steps:**
1. Go to https://developer.safaricom.co.ke
2. Create account (if not already)
3. Create new app → Get **Consumer Key** → Save as `DARAJA_CONSUMER_KEY`
4. Get **Consumer Secret** → Save as `DARAJA_CONSUMER_SECRET`
5. Also save as `MPESA_CONSUMER_SECRET` (same value, for webhook signature verification)
6. Get **Sandbox Test Credentials:**
   - **Shortcode:** Use test number from Daraja dashboard (e.g., `174379` for Paybill)
   - **Passkey:** Use default sandbox passkey from documentation
   - Save as `MPESA_SHORTCODE` and `MPESA_PASSKEY`

**Sandbox Environment:**
- Base URL: `https://sandbox.safaricom.co.ke`
- Use sandbox Consumer Key/Secret
- Test payments work but don't process real money
- Perfect for development and testing

**After n8n is running:**
- [ ] Configure callback URL in Daraja Portal:
  - Your App → Configuration
  - Callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
  - Test STK Push in sandbox

#### Production Setup (Later - When Ready to Go Live)

**When you're ready for real transactions:**
1. Submit "Go Live" request in Daraja Portal (requires business documents)
2. Get **new production credentials:**
   - New Consumer Key (different from sandbox)
   - New Consumer Secret (different from sandbox)
   - Production Shortcode (your actual Till/Paybill number)
   - Production Passkey (from "Go Live" process)
3. Update `.env` with production credentials
4. Change `DARAJA_BASE_URL` to `https://api.safaricom.co.ke`

**Note:** Sandbox is perfect for initial setup and testing. You can switch to production later without changing any code.

---

### 3. Environment Variables Configuration (15 minutes) ⭐ **REQUIRED**

**Create `.env` file:**
```bash
# In project root
cp apps/whatsapp-business/.sample.env .env
# Or create manually and copy from .sample.env
```

**Fill in ALL required variables:**

```bash
# ============================================
# Supabase (✅ Already configured - use your existing values)
# ============================================
SUPABASE_URL=https://dbnlsdxmmdoufzhkrdtd.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_existing_service_role_key  # ✅ You already have this
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRibmxzZHhtbWRvdWZ6aGtyZHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NDU3NzgsImV4cCI6MjA4MzUyMTc3OH0.36WyshuSJUeJhGLplc5BsiB4zC4QuZh-cGjX8in4CDc

# ============================================
# Meta WhatsApp (✅ Already configured - use your existing credentials)
# ============================================
WHATSAPP_ACCESS_TOKEN=your_existing_whatsapp_access_token
WHATSAPP_APP_SECRET=your_existing_app_secret
PHONE_NUMBER_ID=your_existing_phone_number_id

# ============================================
# Webhooks (Generate tokens)
# ============================================
VERIFY_TOKEN=your_generated_token_here  # openssl rand -hex 32
WEBHOOK_VERIFY_TOKEN=your_generated_token_here  # Same as above

# ============================================
# M-Pesa (Sandbox - Start here for testing)
# ============================================
DARAJA_BASE_URL=https://sandbox.safaricom.co.ke  # Sandbox URL (change to https://api.safaricom.co.ke for production)
DARAJA_CONSUMER_KEY=your_sandbox_consumer_key_here
DARAJA_CONSUMER_SECRET=your_sandbox_consumer_secret_here
MPESA_CONSUMER_SECRET=your_sandbox_consumer_secret_here  # Same as above (for webhook signature verification)
MPESA_SHORTCODE=your_sandbox_shortcode_here  # Test number (e.g., 174379 for Paybill)
MPESA_PASSKEY=your_sandbox_passkey_here  # Default sandbox passkey from documentation

# Note: For production, you'll get new credentials via "Go Live" process

# ============================================
# Application
# ============================================
NODE_ENV=development
ALLOW_UNSIGNED_WEBHOOKS=false  # Set to true only for local testing
N8N_BASE_URL=http://localhost:5678

# ============================================
# Optional: SMS Fallback
# ============================================
SMS_PROVIDER=local  # Default: local (uses local SMS tool)
LOCAL_SMS_API_URL=http://localhost:3000
SMS_SENDER_ID=TRADEFAC
```

**Validate environment:**
```bash
node scripts/validate-env.js
# Should show: ✅ All required environment variables are valid
```

---

### 4. n8n Setup & Workflow Import (30 minutes)

**✅ Docker Setup Already Ready** - Just need to start it!

**Start n8n:**
```bash
cd apps/n8n

# Create Docker volume (first time only)
docker volume create n8n_data

# Start n8n
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

**Access n8n:** http://localhost:5678

**Import Workflows (All 12 workflows already created):**
1. Open n8n UI at http://localhost:5678
2. Go to **Workflows** → **Import from File**
3. Import these workflows from `apps/n8n/workflows/` (in order):
   - `00_lookup_tenant_config.json` ⭐ (utility - import first)
   - `01_classify_message_v2.json` ⭐ (updated for Meta)
   - `02_check_consent.json`
   - `03_send_whatsapp_v2.json` ⭐ (updated for Meta)
   - `04_send_sms_fallback_v2.json` ⭐ (updated for local SMS)
   - `05_log_message.json`
   - `06_reconcile_payment_v2.json`
   - `07_send_payment_confirmation_v2.json` ⭐ (updated for Meta)
   - `08_submit_to_etims.json`
   - `09_multi_rail_payment.json`
   - `10_handle_order_with_confirmation.json` (optional - Interakt pattern)
   - `11_reorder_bot.json` (optional - Botomatik pattern)
   - `12_status_broadcast.json` (optional - TechWaba pattern)

**Note:** Workflows 10-12 are "copy-paste wins" based on successful patterns from Interakt, Botomatik, and TechWaba. Import them if you want advanced features like order confirmation flows, reorder automation, or status broadcasts.

**For each workflow:**
- [ ] Review workflow nodes (they're pre-configured)
- [ ] Update environment variable references if needed (they use `{{ $env.VARIABLE_NAME }}`)
- [ ] Activate workflow

**Configure Environment Variables in n8n:**
- Go to **Settings** → **Environment Variables**
- Add all variables from your `.env` file
- Or use n8n Credentials (more secure - recommended)
- **Note:** Workflows reference env vars like `{{ $env.SUPABASE_URL }}`

---

### 5. Configure Webhooks (15 minutes)

**After n8n is running:**

**Meta WhatsApp Webhook:**
1. Get webhook URL from n8n workflow `01_classify_message_v2`:
   - Format: `http://localhost:5678/webhook/whatsapp` (or production URL)
2. Configure in Meta App Dashboard:
   - Settings → WhatsApp → Configuration
   - Webhook URL: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
   - Verify Token: (same as `VERIFY_TOKEN` in .env)
   - Subscribe to: `messages`, `message_status`
3. Test webhook: Send test WhatsApp message
4. Verify webhook received in n8n (check Executions tab)

**M-Pesa Callback:**
1. Get webhook URL from n8n workflow `06_reconcile_payment_v2`:
   - Format: `http://localhost:5678/webhook/mpesa-callback` (or production URL)
2. Configure in Daraja Portal:
   - Your App → Configuration
   - Callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
3. Test STK Push in sandbox
4. Verify callback received in n8n (check Executions tab)

**For Local Testing:**
- Use ngrok: `ngrok http 5678`
- Use ngrok URL in webhook configurations

---

### 6. Testing & Verification (30 minutes)

**Run Health Check:**
```bash
# From project root
node scripts/health-check.js
# Or:
node apps/whatsapp-business/scripts/health-check.js
```

**Expected Output:**
```
🏥 Running Health Checks

✅ Supabase: Connected successfully
✅ n8n: Running
✅ WhatsApp: Provider: meta, Token configured
✅ SMS: Provider: local, Sender ID: TRADEFAC
✅ M-Pesa: Base URL: https://sandbox.safaricom.co.ke, Shortcode: YOUR_SHORTCODE

Summary: 5 ok, 0 skipped, 0 errors
```

**Test Environment Validation:**
```bash
# From project root
node scripts/validate-env.js
# Should show: ✅ All required environment variables are valid
```

**Test All Integrations (Real API Calls):**
```bash
# Comprehensive integration test - makes real API calls
bash scripts/test-env-integrations.sh
# Or:
cd apps/whatsapp-business && NODE_PATH=./node_modules:$NODE_PATH node ../../scripts/test-integrations.js

# This will test:
# ✅ Supabase connection (real query)
# ✅ Meta WhatsApp API (verify token works)
# ✅ M-Pesa Daraja OAuth (get access token)
# ✅ n8n connection (if running)
# ✅ Webhook configuration
```

**Test Database Connection:**
```sql
-- In Supabase SQL Editor (https://supabase.com/dashboard)
-- Or use MCP: mcp_supabase_execute_sql
SELECT COUNT(*) FROM tenants;
SELECT COUNT(*) FROM tenant_config;
-- Should return counts (not errors)
-- ✅ Already has 3 test tenants seeded
```

**Create Test Tenant (Optional - 3 test tenants already exist):**
```sql
-- In Supabase SQL Editor
INSERT INTO tenants (name, phone, is_active) 
VALUES ('Test Trader', '+254712345678', true)
RETURNING id;

-- Copy the UUID, then:
INSERT INTO tenant_config (
  tenant_id, tenant_name, tenant_uuid, 
  waba_phone_number_id, waba_provider,
  mpesa_shortcode, payment_rails, tax_system
) VALUES (
  'test_trader_001',
  'Test Trader',
  'PASTE_UUID_FROM_ABOVE',
  'YOUR_PHONE_NUMBER_ID',
  'meta',
  'YOUR_MPESA_SHORTCODE',
  '[{"rail_type": "mpesa", "enabled": true, "priority": 1}]'::jsonb,
  '{"system": "etims", "pin": "A000000000"}'::jsonb
);

-- Or update existing test tenant:
UPDATE tenant_config 
SET 
  waba_phone_number_id = 'YOUR_PHONE_NUMBER_ID',
  mpesa_shortcode = 'YOUR_MPESA_SHORTCODE',
  payment_rails = '[{"rail_type": "mpesa", "enabled": true, "priority": 1}]'::jsonb
WHERE tenant_id = 'test_trader_001';
```

**Test End-to-End Flow:**
1. Send test WhatsApp message to your business number
2. Verify message received in n8n (check Executions tab)
3. Verify message classified correctly
4. Create test order (manually or via workflow)
5. Initiate M-Pesa STK Push (via workflow or manually)
6. Complete payment in M-Pesa sandbox
7. Verify payment callback received in n8n
8. Verify payment matched to order
9. Verify confirmation message sent

---

## 📋 Quick Checklist

### Required (Must Complete):
- [x] Get Meta WhatsApp credentials (`WHATSAPP_ACCESS_TOKEN`, `PHONE_NUMBER_ID`, `WHATSAPP_APP_SECRET`) ✅ **DONE**
- [x] Get Supabase Service Role Key (`SUPABASE_SERVICE_ROLE_KEY`) ✅ **DONE**
- [ ] Get M-Pesa Daraja **Sandbox** credentials (`DARAJA_CONSUMER_KEY`, `DARAJA_CONSUMER_SECRET`, `MPESA_SHORTCODE`, `MPESA_PASSKEY`)
- [ ] Create `.env` file with all required variables (add your existing credentials)
- [ ] Run `node scripts/validate-env.js` (should pass)
- [ ] Run `node apps/whatsapp-business/scripts/health-check.js` (all services should be ✅)

### Setup (After Credentials):
- [ ] Start n8n (docker-compose up -d) ⚡ Already configured!
- [ ] Import all 12 workflows into n8n ⚡ Workflows already created!
- [ ] Configure environment variables in n8n (Settings → Environment Variables)
- [ ] Configure webhooks in Meta and M-Pesa dashboards
- [ ] Test webhook reception
- [ ] Create test tenant in database (or use existing test tenants)
- [ ] Test end-to-end flow

### Optional (Can Do Later):
- [ ] Set up local SMS tool (for SMS fallback)
- [ ] Set up AfricasTalking (alternative SMS provider)
- [ ] Configure Google Cloud APIs (for voice/image)
- [ ] Set up monitoring/alerts

---

## 🎯 Success Criteria

**Setup is successful when:**
- [ ] Health check shows all services ✅
- [ ] Environment validation passes
- [ ] Test tenant created in database
- [ ] Webhook signature validation working (rejects invalid signatures)
- [ ] End-to-end flow tested (WhatsApp → Order → Payment → Confirmation)
- [ ] No critical errors in logs

---

## 📞 Need Help?

**If stuck:**
1. Check `docs/CLEANUP_SUMMARY.md` for what changed
2. Check `docs/ORCHESTRATION_INDUSTRY_STANDARDS_REVIEW.md` for workflow standards
3. Review error messages in health check output
4. Check Supabase logs for migration errors
5. Check n8n Executions tab for workflow errors

---

**Estimated Total Time:** 2-3 hours  
**Status:** ✅ Infrastructure Ready - Need Credentials Only  
**Next:** Start with Step 1 (Meta WhatsApp Setup)

---

## 📝 Summary: What's Done vs What You Need

### ✅ Fully Implemented (No Action Needed):
- Database schema (8 migrations applied)
- All 12 n8n workflows created
- Docker setup for n8n
- Environment variable template
- Health check & validation scripts
- Webhook server code
- Code cleanup (SMSLeopard → Meta WhatsApp)

### ⚠️ Needs Your Action (Credentials & Setup):
1. ✅ **Meta WhatsApp** - Already configured (just add to `.env`)
2. ✅ **Supabase** - Already configured (just add Service Role Key to `.env`)
3. **Get M-Pesa Sandbox credentials** (Daraja Consumer Key/Secret, Sandbox Shortcode, Sandbox Passkey)
   - ⚠️ **Start with Sandbox** - Production comes later via "Go Live"
4. **Create `.env` file** from `.sample.env` template (add all your existing credentials)
5. **Start n8n** (`docker-compose up -d`)
6. **Import workflows** into n8n (they exist, just need import)
7. **Configure webhooks** in external dashboards (Meta webhook URL, M-Pesa callback)
8. **Test end-to-end** flow

**Time Breakdown:**
- Getting M-Pesa Sandbox credentials: 15-30 minutes (Daraja portal)
- Creating `.env` and setup: 15-30 minutes
- Testing: 30-60 minutes

