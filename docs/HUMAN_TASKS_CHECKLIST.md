# Human Tasks Checklist - Week 1 Implementation

**Date:** January 9, 2026  
**Status:** Ready for Human Intervention  
**Estimated Time:** 4-6 hours

---

## 🚨 CRITICAL: Must Do First (Blocks Everything)

### 1. Supabase Setup (30 minutes)
- [ ] Go to https://supabase.com and create new project
- [ ] Project name: `jander-nairobi`
- [ ] Copy **Project URL** → Save as `SUPABASE_URL`
- [ ] Copy **Service Role Key** → Save as `SUPABASE_SERVICE_ROLE_KEY` (⚠️ Keep secret!)
- [ ] Copy **Anon Key** → Save as `SUPABASE_ANON_KEY`
- [ ] Open SQL Editor in Supabase dashboard
- [ ] Run migration **001**: `apps/supabase/migrations/001_create_trade_facilitator_schema.sql`
- [ ] Run migration **002**: `apps/supabase/migrations/002_add_waas_core_tables.sql`
- [ ] Run migration **003**: `apps/supabase/migrations/003_add_tenant_config.sql`
- [ ] Run migration **004**: `apps/supabase/migrations/004_migrate_to_research_schema.sql`
- [ ] Run migration **005**: `apps/supabase/migrations/005_fix_tenant_config_fk.sql` ⭐ NEW
- [ ] Run migration **006**: `apps/supabase/migrations/006_create_dead_letter_queue.sql` ⭐ NEW
- [ ] Run migration **007**: `apps/supabase/migrations/007_create_error_logs.sql` ⭐ NEW
- [ ] Verify tables: Run `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';`
- [ ] Should see: `tenants`, `orders`, `payments`, `tenant_config`, `dead_letter_queue`, `error_logs`, etc.

**Test:**
```bash
# After setting env vars, test connection
node apps/whatsapp-business/scripts/health-check.js
```

---

### 2. SMSLeopard WhatsApp Setup (1-2 hours)
- [ ] Go to https://smsleopard.co.ke
- [ ] Sign up for WhatsApp Business API account
- [ ] Complete business verification (may take 1-2 days - start now!)
- [ ] Get **API Token** from dashboard → Save as `SMSLEOPARD_TOKEN`
- [ ] Get **Phone Number ID** from dashboard → Save as `PHONE_NUMBER_ID`
- [ ] Generate webhook secret: `openssl rand -hex 32` → Save as `SMSLEOPARD_WEBHOOK_SECRET` ⭐ NEW
- [ ] **Note webhook URL** (will configure after n8n is running):
  - Format: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
- [ ] Generate verify token: `openssl rand -hex 32` → Save as `VERIFY_TOKEN` and `WEBHOOK_VERIFY_TOKEN`

**After n8n is running:**
- [ ] Configure webhook URL in SMSLeopard dashboard
- [ ] Configure webhook secret in SMSLeopard dashboard (must match `SMSLEOPARD_WEBHOOK_SECRET`)
- [ ] Test webhook reception

---

### 3. M-Pesa Daraja Setup (1-2 hours)
- [ ] Go to https://developer.safaricom.co.ke
- [ ] Create account (if not already)
- [ ] Create new app → Get **Consumer Key** → Save as `DARAJA_CONSUMER_KEY`
- [ ] Get **Consumer Secret** → Save as `DARAJA_CONSUMER_SECRET`
- [ ] Also save as `MPESA_CONSUMER_SECRET` (for webhook signature verification) ⭐ NEW
- [ ] Get **Till/Paybill Number** (apply if don't have one) → Save as `MPESA_SHORTCODE`
- [ ] Get **Passkey** from Daraja dashboard → Save as `MPESA_PASSKEY`
  - **Sandbox:** Use default passkey from documentation
  - **Production:** Get from "Go Live" process
- [ ] **Note callback URL** (will configure after n8n is running):
  - Format: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
- [ ] Test STK Push in sandbox (optional but recommended)

**For Production:**
- [ ] Submit "Go Live" request (requires business documents)
- [ ] Get production credentials (different from sandbox)

---

### 4. Environment Variables Configuration (15 minutes)
- [ ] Create `.env` file in project root (or `apps/whatsapp-business/.env`)
- [ ] Copy from `.env.example` (root) or `apps/whatsapp-business/.sample.env`
- [ ] Fill in **all required variables**:
  ```
  # Supabase (from step 1)
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
  SUPABASE_ANON_KEY=your_anon_key
  
  # WhatsApp (from step 2)
  WHATSAPP_PROVIDER=smsleopard
  SMSLEOPARD_TOKEN=your_token
  PHONE_NUMBER_ID=your_phone_number_id
  SMSLEOPARD_WEBHOOK_SECRET=your_webhook_secret  ⭐ NEW
  
  # M-Pesa (from step 3)
  DARAJA_BASE_URL=https://sandbox.safaricom.co.ke
  DARAJA_CONSUMER_KEY=your_consumer_key
  DARAJA_CONSUMER_SECRET=your_consumer_secret
  MPESA_CONSUMER_SECRET=your_consumer_secret  ⭐ NEW (same as above)
  MPESA_SHORTCODE=your_shortcode
  MPESA_PASSKEY=your_passkey
  
  # Webhooks
  VERIFY_TOKEN=your_verify_token
  WEBHOOK_VERIFY_TOKEN=your_verify_token
  
  # Application
  NODE_ENV=development
  LOG_LEVEL=info
  ALLOW_UNSIGNED_WEBHOOKS=false  ⭐ NEW (set to true only for local testing)
  ```
- [ ] Generate missing tokens/secrets:
  ```bash
  # Generate verify tokens
  openssl rand -hex 32
  
  # Generate webhook secrets
  openssl rand -hex 32
  ```
- [ ] Validate environment: `node scripts/validate-env.js`
- [ ] Fix any validation errors

**Test:**
```bash
node scripts/validate-env.js
# Should show: ✅ All required environment variables are valid
```

---

## ⚙️ CONFIGURATION: n8n Setup (1 hour)

### 5. n8n Installation & Configuration
- [ ] Install n8n (if not already installed):
  ```bash
  # Option 1: Docker (recommended)
  cd apps/n8n
  docker-compose up -d
  
  # Option 2: npm
  npm install -g n8n
  n8n start
  ```
- [ ] Access n8n UI: http://localhost:5678
- [ ] Create n8n account (first time setup)
- [ ] Configure environment variables in n8n:
  - Go to Settings → Environment Variables
  - Add all variables from `.env` file
  - Or use n8n Credentials (more secure)

### 6. Import Workflows
- [ ] Import `apps/n8n/workflows/00_lookup_tenant_config.json`
- [ ] Import `apps/n8n/workflows/01_classify_message_v2.json` ⭐ (has signature validation)
- [ ] Import `apps/n8n/workflows/02_check_consent.json`
- [ ] Import `apps/n8n/workflows/03_send_whatsapp_v2.json`
- [ ] Import `apps/n8n/workflows/04_send_sms_fallback_v2.json`
- [ ] Import `apps/n8n/workflows/05_log_message.json`
- [ ] Import `apps/n8n/workflows/06_reconcile_payment_v2.json` ⭐ (has signature validation)
- [ ] Import `apps/n8n/workflows/07_send_payment_confirmation_v2.json`
- [ ] Import `apps/n8n/workflows/08_submit_to_etims.json`
- [ ] Import `apps/n8n/workflows/09_multi_rail_payment.json`

**For each workflow:**
- [ ] Review workflow nodes
- [ ] Verify environment variables are referenced correctly
- [ ] Test workflow with sample data (if possible)
- [ ] Activate workflow

### 7. Configure Webhooks in n8n
- [ ] Get webhook URLs from n8n workflows:
  - WhatsApp: `http://localhost:5678/webhook/whatsapp` (or production URL)
  - M-Pesa: `http://localhost:5678/webhook/mpesa-callback` (or production URL)
- [ ] **Note:** Webhook URLs will be configured in SMSLeopard/M-Pesa dashboards

---

## 🔗 INTEGRATION: Connect Services (30 minutes)

### 8. Configure SMSLeopard Webhook
- [ ] Go to SMSLeopard dashboard → Webhooks
- [ ] Set webhook URL: `https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001`
  - **For local testing:** Use ngrok: `ngrok http 5678` → Use ngrok URL
- [ ] Set verify token: (same as `VERIFY_TOKEN` in .env)
- [ ] Set webhook secret: (same as `SMSLEOPARD_WEBHOOK_SECRET` in .env) ⭐ NEW
- [ ] Save configuration
- [ ] Test webhook: Send test WhatsApp message
- [ ] Verify webhook received in n8n (check Executions tab)
- [ ] **Test signature validation:** Send webhook with invalid signature (should reject 401) ⭐ NEW

### 9. Configure M-Pesa Callback
- [ ] Go to Daraja Portal → Your App → Configuration
- [ ] Set callback URL: `https://your-n8n-instance.com/webhook/mpesa-callback?tenant_id=sme_001`
  - **For local testing:** Use ngrok: `ngrok http 5678` → Use ngrok URL
- [ ] Save configuration
- [ ] Test STK Push in sandbox
- [ ] Verify callback received in n8n (check Executions tab)
- [ ] **Test signature validation:** Send callback with invalid signature (should reject 401) ⭐ NEW

---

## 🧪 TESTING: Verify Everything Works (1 hour)

### 10. Run Health Check
- [ ] Run: `node apps/whatsapp-business/scripts/health-check.js`
- [ ] Verify all services show ✅ (Supabase, WhatsApp, M-Pesa)
- [ ] Fix any errors shown
- [ ] Run with JSON output: `node apps/whatsapp-business/scripts/health-check.js --json`
- [ ] Verify JSON output is valid

### 11. Test Environment Validation
- [ ] Run: `node scripts/validate-env.js`
- [ ] Verify: "✅ All required environment variables are valid"
- [ ] Fix any errors or warnings
- [ ] Run in strict mode: `node scripts/validate-env.js --strict`
- [ ] Address any strict mode warnings

### 12. Test Database Migrations
- [ ] Open Supabase SQL Editor
- [ ] Run: `SELECT COUNT(*) FROM tenants;` (should return 0 or count)
- [ ] Run: `SELECT COUNT(*) FROM tenant_config;` (should return 0 or count)
- [ ] Run: `SELECT COUNT(*) FROM dead_letter_queue;` (should return 0) ⭐ NEW
- [ ] Run: `SELECT COUNT(*) FROM error_logs;` (should return 0) ⭐ NEW
- [ ] Verify `tenant_config.tenant_uuid` column exists: 
  ```sql
  SELECT column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name = 'tenant_config' AND column_name = 'tenant_uuid';
  ```
- [ ] Should return: `tenant_uuid | uuid`

### 13. Create Test Tenant
- [ ] Open Supabase SQL Editor
- [ ] Insert test tenant:
  ```sql
  INSERT INTO tenants (name, phone, is_active) 
  VALUES ('Test Trader', '+254712345678', true)
  RETURNING id;
  ```
- [ ] Copy the returned UUID
- [ ] Insert tenant config:
  ```sql
  INSERT INTO tenant_config (
    tenant_id, tenant_name, tenant_uuid, 
    waba_phone_number_id, waba_provider,
    mpesa_shortcode, payment_rails, tax_system
  ) VALUES (
    'test_trader_001',
    'Test Trader',
    'PASTE_UUID_FROM_ABOVE',
    'YOUR_PHONE_NUMBER_ID',
    'smsleopard',
    'YOUR_MPESA_SHORTCODE',
    '[{"rail_type": "mpesa", "enabled": true, "priority": 1}]'::jsonb,
    '{"system": "etims", "pin": "A000000000"}'::jsonb
  );
  ```
- [ ] Verify tenant config created:
  ```sql
  SELECT * FROM tenant_config WHERE tenant_id = 'test_trader_001';
  ```

### 14. Test End-to-End Flow
- [ ] Send test WhatsApp message to your business number
- [ ] Verify message received in n8n (check Executions tab)
- [ ] Verify message classified correctly
- [ ] Create test order (manually or via workflow)
- [ ] Initiate M-Pesa STK Push (via workflow or manually)
- [ ] Complete payment in M-Pesa sandbox
- [ ] Verify payment callback received in n8n
- [ ] Verify payment matched to order
- [ ] Verify confirmation message sent

---

## 📝 OPTIONAL: Additional Setup

### 15. SMS Fallback (Optional)
- [ ] Choose SMS provider: SMSLeopard SMS or AfricasTalking
- [ ] Sign up and get API key
- [ ] Register sender ID (e.g., "TRADEFAC")
- [ ] Add to `.env`: `SMS_PROVIDER`, `SMSLEOPARD_API_KEY` (or `AFRICASTALKING_API_KEY`)
- [ ] Test SMS sending

### 16. Google Cloud APIs (Optional - for voice/image)
- [ ] Create Google Cloud project
- [ ] Enable Speech-to-Text API
- [ ] Enable Vision API
- [ ] Create service account
- [ ] Download credentials JSON
- [ ] Add to `.env`: `GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json`

### 17. Monitoring Setup (Optional)
- [ ] Set up Slack webhook for alerts
- [ ] Add to `.env`: `SLACK_WEBHOOK_URL=...`
- [ ] Set up Sentry (optional)
- [ ] Add to `.env`: `SENTRY_DSN=...`

---

## ✅ FINAL VERIFICATION

### 18. Pre-Deployment Checklist
- [ ] All migrations run successfully
- [ ] All environment variables configured and validated
- [ ] All workflows imported and activated
- [ ] Webhooks configured and receiving messages
- [ ] Health check passes: `node apps/whatsapp-business/scripts/health-check.js`
- [ ] Environment validation passes: `node scripts/validate-env.js`
- [ ] Test tenant created in database
- [ ] End-to-end flow tested successfully
- [ ] Webhook signature validation tested (invalid signature rejected)
- [ ] Error logs table accessible
- [ ] Dead letter queue table accessible

### 19. Production Readiness
- [ ] Set `NODE_ENV=production` in production environment
- [ ] Set `ALLOW_UNSIGNED_WEBHOOKS=false` in production
- [ ] Verify `SMSLEOPARD_WEBHOOK_SECRET` is set in production
- [ ] Verify `MPESA_CONSUMER_SECRET` is set in production
- [ ] Update webhook URLs to production domain (not localhost/ngrok)
- [ ] Test production webhooks
- [ ] Set up monitoring/alerts
- [ ] Document production credentials (securely)

---

## 🎯 Success Criteria

**Week 1 is successful when:**
- [ ] All 7 migrations run successfully
- [ ] Health check shows all services ✅
- [ ] Environment validation passes
- [ ] Test tenant created and accessible
- [ ] Webhook signature validation working (rejects invalid signatures)
- [ ] End-to-end flow tested (WhatsApp → Order → Payment → Confirmation)
- [ ] No critical errors in logs

---

## 📞 Need Help?

**If stuck on any step:**
1. Check `docs/IMPLEMENTATION_STATUS.md` for implementation details
2. Check `docs/core/WhatsApp_Commerce_Technical_KB.md` for service-specific guides
3. Check `docs/HUMAN_HANDOFF_CHECKLIST.md` for detailed instructions
4. Review error messages in health check output
5. Check Supabase logs for migration errors
6. Check n8n Executions tab for workflow errors

---

**Estimated Total Time:** 4-6 hours  
**Status:** Ready to begin  
**Next:** Start with Step 1 (Supabase Setup)

