# Tomorrow's Action Plan - Complete Human Checklist

**Everything you need to continue building tomorrow. Follow this step-by-step.**

**Estimated Time**: 2-3 hours for Priority 1 (credentials + setup)  
**Goal**: Get all credentials, run migrations, test workflows 1-2, 5-6

---

## 🎯 Priority 1: Get API Credentials (2-3 hours)

### Step 1: Supabase Setup (15 minutes)

**Why**: Database for all operations. Required for workflows 1, 2, 5, 6.

**Actions**:
1. Go to https://supabase.com
2. Sign up / Log in
3. Click "New Project"
4. Fill in:
   - Project name: `jander-trade-facilitator`
   - Database password: (save this!)
   - Region: Choose closest to Kenya
5. Wait for project creation (~2 minutes)
6. Go to Project Settings → API
7. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Service Role Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long string)
   - **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (shorter string)

**Save to**: `.env` file (see Step 8 below)

**✅ Success**: You have 3 values copied (URL, service role key, anon key)

---

### Step 2: Run Database Migrations (10 minutes)

**Why**: Create all 13 tables needed for the system.

**Actions**:
1. In Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open file: `apps/supabase/migrations/001_create_trade_facilitator_schema.sql`
4. Copy ALL contents (252 lines)
5. Paste into Supabase SQL Editor
6. Click **Run** (or press Cmd+Enter)
7. Wait for success message: "Success. No rows returned"
8. Repeat for: `apps/supabase/migrations/002_add_waas_core_tables.sql`
9. Verify tables created:
   - Go to **Table Editor** (left sidebar)
   - You should see: `buyers`, `sellers`, `trades`, `products`, `conversations`, `payments`, `payouts`, `consent`, `message_logs`, `audit_logs`, `agents`, `merchant_outlets`, `daily_logs`

**✅ Success**: 13 tables visible in Table Editor

**Troubleshooting**:
- If error: "relation already exists" → Table already created, skip
- If error: "permission denied" → Check you're using SQL Editor (not Table Editor)

---

### Step 3: SMSLeopard WhatsApp Business API (30-60 minutes)

**Why**: Required for workflows 3, 7 (sending WhatsApp messages).

**Actions**:
1. Go to https://smsleopard.co.ke/whatsapp-business.html
2. Click "Get Started" or "Sign Up"
3. Fill in registration form:
   - Business name
   - Email
   - Phone number
   - Business type
4. Verify email (check inbox)
5. Log in to dashboard
6. Go to **WhatsApp Business** section
7. Request WhatsApp Business Account (if not already done)
8. Once approved, go to **API Settings** or **Integration**
9. Copy these values:
   - **API Token**: `Bearer xxxxx...`
   - **Phone Number ID**: `123456789012345`
   - **Webhook Verify Token**: Generate one (e.g., `be3af374eb774e0c1c62b4c756f7495c8896fe0dc5c2428d4bbfd4d9cf2a75a8`)

**Save to**: `.env` file (see Step 8 below)

**✅ Success**: You have API token, Phone Number ID, and verify token

**Note**: Approval may take 24-48 hours. You can continue with other steps while waiting.

---

### Step 4: SMS Provider Setup (15-30 minutes)

**Why**: Required for workflow 4 (SMS fallback when WhatsApp fails).

**Option A: SMSLeopard (Recommended - same account as WhatsApp)**
1. In SMSLeopard dashboard, go to **SMS** section
2. Go to **API Settings**
3. Copy **API Key**: `xxxxx...`
4. Register **Sender ID**: `TRADEFAC` (or your preferred name)
5. Wait for approval (usually instant or 24 hours)

**Option B: AfricasTalking (Alternative)**
1. Go to https://africastalking.com
2. Sign up / Log in
3. Go to **Settings** → **API Keys**
4. Copy **API Key**
5. Register **Sender ID**: `TRADEFAC`

**Save to**: `.env` file (see Step 8 below)

**✅ Success**: You have SMS API key and sender ID

---

### Step 5: M-Pesa Daraja API (Sandbox) (30-60 minutes)

**Why**: Required for payment processing (STK Push, B2C payouts).

**Actions**:
1. Go to https://developer.safaricom.co.ke
2. Click **Get Started** or **Register**
3. Fill in registration:
   - Email
   - Phone number
   - Business details
4. Verify email
5. Log in to dashboard
6. Go to **My Apps** → **Create App**
7. Fill in:
   - App name: `jander-trade-facilitator`
   - Description: `WhatsApp commerce platform`
8. Click **Create**
9. Copy these values:
   - **Consumer Key**: `xxxxx...`
   - **Consumer Secret**: `xxxxx...`
10. Go to **Sandbox** section
11. Copy:
    - **Shortcode**: `174379` (test shortcode)
    - **Passkey**: `bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919` (test passkey)
    - **Base URL**: `https://sandbox.safaricom.co.ke`

**Save to**: `.env` file (see Step 8 below)

**✅ Success**: You have consumer key, secret, shortcode, passkey, base URL

**Note**: Sandbox credentials are sufficient for testing. Live credentials require business registration.

---

### Step 6: Environment Variables Setup (10 minutes)

**Why**: All services need credentials to run.

**Actions**:
1. Navigate to project root:
   ```bash
   cd /Users/jaabirahmed/Documents/projects/jander/apps/whatsapp-business
   ```
2. Copy sample env file:
   ```bash
   cp .sample.env .env
   ```
3. Open `.env` in your editor
4. Fill in ALL values from Steps 1-5 above:

```bash
# Supabase (from Step 1)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# WhatsApp (SMSLeopard - from Step 3)
WHATSAPP_PROVIDER=smsleopard
SMSLEOPARD_TOKEN=Bearer xxxxx...
PHONE_NUMBER_ID=123456789012345
WEBHOOK_VERIFY_TOKEN=be3af374eb774e0c1c62b4c756f7495c8896fe0dc5c2428d4bbfd4d9cf2a75a8

# SMS Provider (from Step 4)
SMS_PROVIDER=smsleopard
SMSLEOPARD_API_KEY=xxxxx...
SMS_SENDER_ID=TRADEFAC

# M-Pesa Daraja (from Step 5)
DARAJA_BASE_URL=https://sandbox.safaricom.co.ke
DARAJA_CONSUMER_KEY=xxxxx...
DARAJA_CONSUMER_SECRET=xxxxx...
MPESA_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919

# Optional: Google Cloud (for voice/image parsing)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

5. Save file
6. **IMPORTANT**: Verify `.env` is in `.gitignore` (should already be there)

**✅ Success**: `.env` file exists with all values filled

**Security Note**: Never commit `.env` to Git. It's already in `.gitignore`.

---

## 🎯 Priority 2: Test What's Built (30 minutes)

### Step 7: Test Services Load (5 minutes)

**Why**: Verify all services can load with credentials.

**Actions**:
```bash
cd /Users/jaabirahmed/Documents/projects/jander/apps/whatsapp-business

# Test services load
node -e "const tf = require('./services/trade-facilitator.js'); console.log('✅ Trade Facilitator loads');"
node -e "const ml = require('./services/message-logger.js'); console.log('✅ Message Logger loads');"
node -e "const pr = require('./services/payment-reconciler.js'); console.log('✅ Payment Reconciler loads');"
```

**✅ Success**: All services load without errors

---

### Step 8: Setup n8n (15 minutes)

**Why**: Run workflows 1, 2, 5, 6.

**Actions**:
1. Install n8n (if not already):
   ```bash
   npm install -g n8n
   ```
2. Start n8n:
   ```bash
   n8n start
   ```
3. Open browser: http://localhost:5678
4. Set environment variables in n8n:
   - Go to **Settings** → **Environment Variables**
   - Add all variables from `.env` file:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`
     - `SUPABASE_SERVICE_ROLE_KEY`
     - `SMSLEOPARD_TOKEN`
     - `PHONE_NUMBER_ID`
     - etc.
5. Import workflows:
   - Click **Workflows** → **Import from File**
   - Import: `apps/n8n/workflows/01_classify_message.json`
   - Import: `apps/n8n/workflows/02_check_consent.json`
   - Import: `apps/n8n/workflows/05_log_message.json`
   - Import: `apps/n8n/workflows/06_reconcile_payment.json`
6. Activate workflows (toggle switch on each)

**✅ Success**: n8n running, 4 workflows imported and activated

---

### Step 9: Test Workflow 1 (classify_message) (10 minutes)

**Why**: Verify message classification works.

**Actions**:
1. In n8n, open workflow `01_classify_message`
2. Click on **WhatsApp Webhook** node
3. Copy the **Webhook URL** (e.g., `http://localhost:5678/webhook/whatsapp`)
4. Test with curl:
   ```bash
   curl -X POST http://localhost:5678/webhook/whatsapp \
     -H "Content-Type: application/json" \
     -d '{
       "message": {
         "id": "test_001",
         "from": "+254700456789",
         "type": "text",
         "timestamp": "1704787200",
         "text": {
           "body": "I want 2m red chiffon"
         }
       }
     }'
   ```
5. Check workflow execution:
   - Go to **Executions** tab
   - You should see a successful execution
   - Check output: Should have `message_type: "order"`, `user_type: "new_user"`, etc.

**✅ Success**: Workflow executes and returns classification

**Troubleshooting**:
- If error: "Supabase connection failed" → Check SUPABASE_URL and keys in n8n env vars
- If error: "Webhook not found" → Make sure workflow is activated

---

## 🎯 Priority 3: Configure Webhooks (15 minutes)

### Step 10: Configure SMSLeopard Webhook (15 minutes)

**Why**: Receive incoming WhatsApp messages.

**Actions**:
1. In SMSLeopard dashboard, go to **WhatsApp** → **Webhooks**
2. Click **Add Webhook** or **Configure**
3. Fill in:
   - **Webhook URL**: `http://your-domain.com:5678/webhook/whatsapp` (or use ngrok for local testing)
   - **Verify Token**: Same as `WEBHOOK_VERIFY_TOKEN` in `.env`
   - **Events**: Select "messages", "message_status"
4. Save
5. Test webhook:
   - Send a WhatsApp message to your business number
   - Check n8n executions: Should see webhook received

**✅ Success**: Webhook configured and receiving messages

**Note**: For local testing, use ngrok:
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 5678
# Copy the https URL (e.g., https://xxxxx.ngrok.io)
# Use this URL in SMSLeopard webhook configuration
```

---

## 📋 Quick Reference Commands

### Start Services
```bash
# Start n8n
n8n start

# Start WhatsApp service (if needed)
cd apps/whatsapp-business
npm start
```

### Test Database Connection
```bash
cd apps/whatsapp-business
node -e "
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
supabase.from('buyers').select('count').then(r => console.log('✅ Database connected:', r));
"
```

### Test Workflow
```bash
# Test classify_message workflow
curl -X POST http://localhost:5678/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"message": {"id": "test", "from": "+254700456789", "type": "text", "text": {"body": "I want 2m red chiffon"}}}'
```

---

## ✅ Success Checklist

**By end of tomorrow, you should have:**

- [ ] Supabase project created
- [ ] Database migrations run (13 tables created)
- [ ] SMSLeopard account created
- [ ] SMS provider account created
- [ ] M-Pesa Daraja sandbox account created
- [ ] `.env` file filled with all credentials
- [ ] n8n running with 4 workflows imported
- [ ] Workflow 1 (classify_message) tested successfully
- [ ] SMSLeopard webhook configured (or ngrok setup for local testing)

**If all checked**: You're ready to continue building workflows 3, 4, 7 and test end-to-end flows!

---

## 🚨 Troubleshooting

### "Supabase connection failed"
- Check `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in `.env`
- Verify project is active in Supabase dashboard
- Check network connection

### "n8n workflow not executing"
- Make sure workflow is **activated** (toggle switch)
- Check environment variables in n8n settings
- Check webhook URL is correct

### "SMSLeopard webhook not receiving"
- Verify webhook URL is accessible (use ngrok for local)
- Check verify token matches
- Test with curl first

### "Database migration errors"
- Check you're using SQL Editor (not Table Editor)
- If "relation exists" error: Table already created, skip
- If permission error: Check you're logged in as project owner

---

## 📞 Support Resources

**Documentation**:
- `docs/HUMAN_INTERVENTION_CHECKLIST.md` - Detailed checklist
- `docs/BUILD_PROGRESS.md` - What's built vs blocked
- `docs/WAAS_ARCHITECTURE.md` - System architecture
- `apps/n8n/workflows/README.md` - Workflow guide

**Account Links**:
- Supabase: https://supabase.com
- SMSLeopard: https://smsleopard.co.ke
- M-Pesa Developer: https://developer.safaricom.co.ke
- n8n: https://n8n.io

---

## 🎯 Tomorrow's Goal

**Primary Goal**: Get all credentials, run migrations, test workflows 1, 2, 5, 6

**Secondary Goal**: Configure webhooks, test end-to-end message flow

**Time Estimate**: 2-3 hours for Priority 1, 30 minutes for Priority 2-3

**Success Metric**: You can send a test WhatsApp message and see it classified in n8n

---

**Last Updated**: 2026-01-09  
**Status**: Ready for tomorrow's execution  
**Next**: Follow steps 1-10 above, then continue building workflows 3, 4, 7

