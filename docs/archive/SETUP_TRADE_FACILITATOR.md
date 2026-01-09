# Trade Facilitator Setup Guide

**Step-by-step setup for the Trade Facilitator hub-and-spoke model.**

This guide walks you through setting up the Trade Facilitator: single WABA orchestrating buyer-seller trades.

---

## Prerequisites

1. **SMSLeopard Account** (WhatsApp Business API via Meta Partner)
   - Sign up at https://smsleopard.co.ke/whatsapp-business.html
   - Get API Token, Phone Number ID, Webhook URL
   - Note: M-Pesa payment supported for Kenyan accounts

2. **Supabase Project** (Database)
   - Sign up at https://supabase.com
   - Create project (free tier: 500MB, 50K monthly users)
   - Get Project URL and Service Role Key

3. **M-Pesa Daraja API** (Sandbox for testing)
   - Register at https://developer.safaricom.co.ke
   - Create app, get Consumer Key & Consumer Secret
   - For live: Submit business docs (KRA PIN, company registration)

4. **n8n Instance** (Automation - optional but recommended)
   - Self-hosted (free) or n8n.cloud (paid)
   - For webhook processing and workflow automation

---

## Step 1: Environment Variables

Create `.env` file in `apps/whatsapp-business/`:

```bash
# WhatsApp Configuration
WHATSAPP_PROVIDER=smsleopard  # or 'meta' if direct access available
SMSLEOPARD_TOKEN=your_smsleopard_token
PHONE_NUMBER_ID=your_phone_number_id
WEBHOOK_VERIFY_TOKEN=your_verify_token
WEBHOOK_SECRET=your_webhook_secret

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# M-Pesa Daraja Configuration
DARAJA_BASE_URL=https://sandbox.safaricom.co.ke  # or https://api.safaricom.co.ke for live
DARAJA_CONSUMER_KEY=your_consumer_key
DARAJA_CONSUMER_SECRET=your_consumer_secret
MPESA_SHORTCODE=your_till_or_paybill_number
MPESA_PASSKEY=your_passkey
MPESA_CALLBACK_URL=https://your-domain.com/mpesa/callback
MPESA_INITIATOR_NAME=your_initiator_name
MPESA_SECURITY_CREDENTIAL=your_security_credential

# Server Configuration
PORT=3000
NODE_ENV=development
```

---

## Step 2: Database Setup

### Run Migration

```bash
cd apps/supabase

# If using Supabase CLI
supabase db push migrations/001_create_trade_facilitator_schema.sql

# Or run manually in Supabase SQL Editor:
# Copy contents of migrations/001_create_trade_facilitator_schema.sql
# Paste into Supabase SQL Editor
# Execute
```

### Verify Tables Created

```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Should return:
-- buyers
-- conversations
-- payments
-- payouts
-- products
-- sellers
-- trades
```

---

## Step 3: Install Dependencies

```bash
cd apps/whatsapp-business
npm install
```

This installs:
- `@supabase/supabase-js` - Database client
- `axios` - HTTP client for M-Pesa API

---

## Step 4: Configure Webhook (SMSLeopard)

### 4.1 Set Up Webhook Endpoint

Your webhook endpoint should be publicly accessible:

```bash
# Option 1: Use ngrok for local testing
ngrok http 3000

# Option 2: Deploy to Heroku/Railway/Render
# Set webhook URL: https://your-domain.com/webhook
```

### 4.2 Configure SMSLeopard Webhook

1. Go to SMSLeopard dashboard
2. Navigate to WhatsApp → Webhooks
3. Set Webhook URL: `https://your-domain.com/webhook`
4. Set Verify Token: (use same as `WEBHOOK_VERIFY_TOKEN` in .env)
5. Enable events: `messages`, `statuses`

### 4.3 Test Webhook

```bash
# Test webhook verification
curl -X GET "https://your-domain.com/webhook?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=test123"

# Should return: test123
```

---

## Step 5: Submit WhatsApp Templates

### 5.1 Create Templates

Templates are defined in `templates/trade-facilitator-templates.json`.

Core templates needed:
1. `new_order_to_seller` - Notify seller of new order
2. `payment_link_to_buyer` - Send payment request to buyer
3. `payment_confirmation` - Confirm payment received
4. `delivery_confirmation_request` - Request delivery confirmation
5. `order_status_update` - Send status updates

### 5.2 Submit to SMSLeopard

1. Go to SMSLeopard dashboard → WhatsApp → Templates
2. Create new template for each template in JSON file
3. Wait for approval (typically 24-48 hours)
4. Track approval status

**Template Example (`new_order_to_seller`):**
```
Template Name: new_order_to_seller
Category: ORDER_UPDATE
Language: en
Content:
New Order!

Buyer {{1}} wants {{2}} × {{3}} for KSh {{4}}.

Delivery area: {{5}}

Reply CONFIRM to accept or REJECT to decline.

Variables:
{{1}} - buyer_name
{{2}} - product_name
{{3}} - quantity
{{4}} - total
{{5}} - delivery_area
```

---

## Step 6: Test Trade Flow

### 6.1 Test Buyer Order (Text Message)

```bash
# Send test WhatsApp message from buyer
# Message: "I want 2m red chiffon, Jane, +254700456789"

# Expected flow:
# 1. Message received → Trade Facilitator processes
# 2. Order parsed → Trade created
# 3. Seller notified (template if outside 24h, session if within)
# 4. Seller replies: CONFIRM or REJECT
# 5. If CONFIRM → Payment link sent to buyer
```

### 6.2 Test Payment (STK Push)

```bash
# After seller confirms:
# 1. STK push sent to buyer
# 2. Buyer completes payment via M-Pesa
# 3. Payment webhook received
# 4. Payment matched to trade
# 5. Both buyer and seller notified
```

### 6.3 Test Delivery → Payout

```bash
# After payment:
# 1. Seller marks order READY
# 2. Seller marks DISPATCHED
# 3. Buyer receives delivery confirmation request
# 4. Buyer replies: YES (confirmed delivery)
# 5. B2C payout initiated to seller
# 6. Seller receives payout notification
```

---

## Step 7: Monitor & Test

### 7.1 Check Database

```sql
-- Check trades created
SELECT * FROM trades ORDER BY created_at DESC LIMIT 10;

-- Check conversations active
SELECT * FROM conversations WHERE status = 'active' ORDER BY expires_at DESC;

-- Check payments
SELECT * FROM payments ORDER BY created_at DESC LIMIT 10;

-- Check payouts
SELECT * FROM payouts ORDER BY created_at DESC LIMIT 10;
```

### 7.2 Monitor Logs

```bash
# Run server
npm start

# Check logs for:
# - Webhook received
# - Message processed
# - Trade created
# - Payment matched
# - Payout initiated
```

---

## Troubleshooting

### Webhook Not Receiving Messages

1. **Check webhook URL**: Ensure publicly accessible (use ngrok for local)
2. **Check verify token**: Must match SMSLeopard dashboard
3. **Check webhook signature**: Verify HMAC signature matches
4. **Check logs**: Look for errors in server logs

### Templates Not Approved

1. **Check template content**: Must follow Meta's template guidelines
2. **Check variables**: Must match exactly (case-sensitive)
3. **Wait for approval**: Typically 24-48 hours
4. **Check SMSLeopard dashboard**: Track approval status

### Database Errors

1. **Check Supabase connection**: Verify URL and key
2. **Check RLS policies**: Ensure service role key has permissions
3. **Check table existence**: Run migration if tables missing
4. **Check indexes**: Verify indexes created for performance

### Payment Issues

1. **Check Daraja credentials**: Verify Consumer Key/Secret
2. **Check STK push**: Verify shortcode and passkey
3. **Check webhook URL**: M-Pesa callbacks must be publicly accessible
4. **Check sandbox vs live**: Use sandbox for testing

---

## Next Steps

1. **Week 1**: Complete setup, test basic flow (1-2 test trades)
2. **Week 2**: Submit templates, wait for approval, test templates
3. **Week 3**: Add WhatsApp Flows (product catalog, quantity selector)
4. **Week 4**: Add conversation window management, optimize flows
5. **Week 5**: Add analytics, monitoring, error handling

---

## References

- **Architecture**: See [`../docs/TRADE_FACILITATOR_ARCHITECTURE.md`](../../docs/TRADE_FACILITATOR_ARCHITECTURE.md)
- **Integration Capabilities**: See [`../docs/INTEGRATION_CAPABILITIES.md`](../../docs/INTEGRATION_CAPABILITIES.md)
- **Week 1 Plan**: See [`../docs/WEEK1_EXECUTION_PLAN.md`](../../docs/WEEK1_EXECUTION_PLAN.md)
- **Test Cases**: See [`../../tests/INTEGRATION_TESTS.md`](../../tests/INTEGRATION_TESTS.md)

---

**Last Updated**: 2026-01-09  
**Status**: Setup guide created, implementation in progress

