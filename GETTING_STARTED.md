# Getting Started - Detailed Week 1 Implementation Guide

**Note:** For quick prerequisites checklist, see [`SETUP.md`](./SETUP.md). For detailed execution plan, see [`docs/WEEK1_EXECUTION_PLAN.md`](./docs/WEEK1_EXECUTION_PLAN.md).

This guide provides step-by-step instructions to get from zero to a working automation system.

---

## Quick Start (30 minutes)

---

## Step 1: Prerequisites Setup (15 minutes)

### 1.1 SMSLeopard Account (5 mins)
1. Go to https://smsleopard.co.ke/whatsapp-business.html
2. Sign up with business name + KRA PIN
3. Get your credentials:
   - API Token
   - Phone Number ID
4. Save these - you'll need them for `.env`

### 1.2 n8n Installation (5 mins)
**Option A: Local (Recommended)**
```bash
npm install -g n8n
n8n start
```
- Access at: http://localhost:5678

**Option B: Cloud**
- Sign up at https://n8n.io
- Free tier: 2,500 executions/month

### 1.3 ngrok Setup (5 mins)
```bash
# Install
brew install ngrok  # Mac
# or download from ngrok.com

# Sign up and get token
# https://dashboard.ngrok.com/get-started/setup

# Authenticate
ngrok config add-authtoken YOUR_TOKEN

# Test
ngrok http 5678  # For n8n
```

---

## Step 2: Environment Setup (5 minutes)

### 2.1 Create `.env` file
Copy `.env.example` to `.env` and fill in:

```bash
cp .env.example .env
```

Edit `.env` with your credentials:
- SMSLeopard API token and Phone Number ID
- Google Sheets ID (create sheet first - Step 3)
- M-Pesa Daraja credentials (get from safaricom.co.ke)

### 2.2 Install Dependencies
```bash
cd apps/scripts
npm install
```

---

## Step 3: Google Sheets Setup (10 minutes)

### 3.1 Create Google Sheet
1. Create new Google Sheet
2. Create 5 sheets: `TRADERS`, `PRODUCTS`, `ORDERS`, `PAYMENTS`, `DAILY_LOG`
3. Use schema from `docs/ARCHITECTURE.md` (Section: Data Schema)

### 3.2 Set Up Columns

**ORDERS Sheet:**
```
A: order_id
B: order_date
C: trader_id
D: customer_name
E: customer_phone
F: product_name
G: quantity
H: unit_price
I: total_kes
J: payment_status
K: payment_ref
L: dispatch_status
M: dispatch_date
N: notes
```

### 3.3 Get Sheet ID
- URL format: `https://docs.google.com/spreadsheets/d/SHEET_ID/edit`
- Copy SHEET_ID to `.env` as `GOOGLE_SHEETS_ID`

### 3.4 Set Up Service Account (for API access)
1. Go to https://console.cloud.google.com
2. Create project
3. Enable "Google Sheets API"
4. Create service account → Download JSON
5. Save to `./credentials/google-credentials.json`
6. Share Google Sheet with service account email

---

## Step 4: n8n Workflows Setup (15 minutes)

### 4.1 Import Workflows
1. Open n8n (http://localhost:5678)
2. Click "Workflows" → "Import from File"
3. Import in order:
   - `apps/n8n/smsleopard-webhook-receiver.json`
   - `apps/n8n/order-processing.json`
   - `apps/n8n/media-processing.json`
   - `apps/n8n/payment-matching.json`

### 4.2 Configure Workflows

**SMSLeopard Webhook Receiver:**
1. Open workflow
2. Click "Webhook" node
3. Copy webhook URL (e.g., `http://localhost:5678/webhook/whatsapp`)
4. Use ngrok to expose: `ngrok http 5678`
5. Copy ngrok HTTPS URL (e.g., `https://abc123.ngrok.io`)
6. Configure SMSLeopard dashboard:
   - Webhook URL: `https://abc123.ngrok.io/webhook/whatsapp`

**Order Processing:**
1. Configure Google Sheets credentials (OAuth)
2. Update Sheet ID in nodes
3. Update SMSLeopard API base URL

**Payment Matching:**
1. Configure M-Pesa webhook URL
2. Update Google Sheets credentials
3. Test with Daraja sandbox

### 4.3 Activate Workflows
- Click "Activate" on each workflow
- Ensure webhook URLs are accessible via ngrok

---

## Step 5: Test End-to-End (10 minutes)

### 5.1 Test WhatsApp Webhook
1. Send WhatsApp message to your SMSLeopard number
2. Check n8n execution logs
3. Verify message received

### 5.2 Test Order Processing
1. Send order: "2m red chiffon, Jane, +254700456789"
2. Verify:
   - [ ] Order created in Google Sheets
   - [ ] Order ID generated
   - [ ] Confirmation sent to customer

### 5.3 Test Payment Matching
1. Create test order
2. Simulate M-Pesa payment via Daraja sandbox
3. Verify:
   - [ ] Payment matched to order
   - [ ] Payment status updated
   - [ ] Confirmation sent

---

## Step 6: Verify Complete Automation Chain

**Test Flow:**
```
WhatsApp Order → SMSLeopard → n8n → Google Sheets → Order Created
                                                          ↓
Customer Pays → M-Pesa → n8n → Match Payment → Update Status → Confirm
```

**Success Criteria:**
- [ ] All workflows active
- [ ] Webhooks receiving messages
- [ ] Orders created automatically
- [ ] Payments matched automatically
- [ ] Confirmations sent automatically
- [ ] Zero manual steps (except dispatch)

---

## Troubleshooting

### Webhook Not Receiving
- Check ngrok is running: `ngrok http 5678`
- Verify webhook URL in SMSLeopard dashboard
- Check n8n workflow is activated
- Review n8n execution logs

### Google Sheets Not Updating
- Verify service account has edit access
- Check Sheet ID in `.env` and workflow nodes
- Review Google Sheets API credentials
- Check n8n execution logs for errors

### Payment Not Matching
- Verify M-Pesa webhook URL configured
- Check phone number format matches
- Verify amount tolerance (±KSh 50)
- Review DAILY_LOG for unmatched payments

---

## Next Steps

After Week 1 is working:
1. Review `docs/BUILD_PLAN.md` for Week 2 tasks
2. Onboard first 5 traders
3. Monitor metrics dashboard
4. Iterate based on feedback

---

## Support

- Check `docs/ARCHITECTURE.md` for technical details
- Review `tests/test-scenarios.md` for test cases
- See `traders/onboarding-template.md` for trader setup

