# Setup Guide - Week 1 Prerequisites & Implementation

**Quick Reference:** This guide covers prerequisites and step-by-step implementation. For detailed execution plan, see [`docs/WEEK1_EXECUTION_PLAN.md`](./docs/WEEK1_EXECUTION_PLAN.md).

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] SMSLeopard WhatsApp Business API account
- [ ] n8n installed (local) or cloud account
- [ ] ngrok installed and authenticated
- [ ] Google account (for Sheets API)
- [ ] M-Pesa Daraja sandbox account
- [ ] `.env` file created (from `.sample.env` template)

**Total Setup Time:** ~40 minutes

---

## 1. SMSLeopard WhatsApp Business API Setup (Priority #1)

**Purpose:** Webhook gateway for automation (NOT bulk messaging)

### Steps:
1. Go to https://smsleopard.co.ke/whatsapp-business.html
2. Sign up with business name + KRA PIN
3. Complete business verification (usually instant for sandbox)
4. Get credentials:
   - API Token
   - Phone Number ID
   - Webhook configuration URL
5. Save credentials to `.env` file (use `.env.example` as template)

### Configuration:
- Copy `.env.example` to `.env`
- Fill in SMSLeopard credentials
- Webhook URL will be set up after n8n is running (Day 1)

**Time:** ~5 minutes
**Cost:** KSh 1,999/mo starter plan (10K messages)

---

## 2. n8n Setup (Priority #2 - Automation Engine)

**Purpose:** Core automation infrastructure

### Option A: Cloud (Easiest)
1. Sign up at https://n8n.io
2. Free tier: 2,500 workflow executions/month
3. Access dashboard immediately
4. Create webhook workflows

### Option B: Local (Recommended for development)
```bash
npm install -g n8n
n8n start
```
- Access at: http://localhost:5678
- Unlimited executions locally
- Better for development and testing

**Time:** ~5 minutes
**Cost:** Free (local) or free tier (cloud)

---

## 3. ngrok Setup (For Local Webhooks)

**Purpose:** Expose local n8n webhooks to internet

### Steps:
1. Install: `brew install ngrok` (Mac) or download from ngrok.com
2. Sign up at https://dashboard.ngrok.com (free)
3. Get auth token from dashboard
4. Authenticate: `ngrok config add-authtoken YOUR_TOKEN`
5. Test: `ngrok http 5678` (for n8n) or `ngrok http 3000` (for Express)

### Usage:
- Run `ngrok http 5678` in separate terminal
- Copy HTTPS URL (e.g., `https://abc123.ngrok.io`)
- Use this URL for SMSLeopard webhook configuration

**Time:** ~5 minutes
**Cost:** Free

---

## 4. Google Account Setup

**Purpose:** Google Sheets database

### Steps:
1. Use existing Gmail account or create new one
2. For Google Sheets API access:
   - Go to https://console.cloud.google.com
   - Create project (or use existing)
   - Enable "Google Sheets API"
   - Create service account → Download JSON credentials
   - Save to `./credentials/google-credentials.json`
3. Share Google Sheet with service account email (once sheet is created)

**Time:** ~5 minutes
**Cost:** Free

---

## 5. M-Pesa Daraja Sandbox Setup

**Purpose:** Payment webhook for automation matching

### Steps:
1. Register at https://developer.safaricom.co.ke
2. Create app → Get Consumer Key & Consumer Secret
3. Test C2B simulation endpoint:
   ```
   https://sandbox.safaricom.co.ke/mpesa/c2b/v2/simulate
   ```
4. Get sandbox credentials:
   - Consumer Key
   - Consumer Secret
   - Test phone numbers
5. Save to `.env` file

**Time:** ~20 minutes
**Cost:** Free (sandbox)

---

## Quick Start Checklist

- [ ] SMSLeopard account created → Credentials saved to `.env`
- [ ] n8n installed/running (local or cloud)
- [ ] ngrok installed and authenticated
- [ ] Google account ready → Service account credentials downloaded
- [ ] M-Pesa Daraja sandbox account → Credentials saved to `.env`
- [ ] `.env` file created from `.env.example`

**Total Setup Time:** ~40 minutes

---

---

## Quick Implementation Steps

After prerequisites are complete:

### Step 1: Environment Configuration
```bash
# Copy sample env file
cp apps/whatsapp-business/.sample.env apps/whatsapp-business/.env

# Edit .env with your credentials
nano apps/whatsapp-business/.env
```

### Step 2: Google Sheets Setup
1. Create Google Sheet with 5 sheets: `TRADERS`, `PRODUCTS`, `ORDERS`, `PAYMENTS`, `DAILY_LOG`
2. Use schema from `docs/ARCHITECTURE.md`
3. Share with service account email (from `credentials/google-credentials.json`)

### Step 3: n8n Workflows Import
1. Open n8n (http://localhost:5678)
2. Import workflows from `apps/n8n/` directory:
   - `smsleopard-webhook-receiver.json`
   - `order-processing.json`
   - `payment-matching.json`
   - `media-processing.json`

### Step 4: Webhook Configuration
1. Start ngrok: `ngrok http 5678`
2. Copy HTTPS URL (e.g., `https://abc123.ngrok.io`)
3. Configure SMSLeopard webhook: `https://abc123.ngrok.io/webhook/whatsapp`

### Step 5: Test End-to-End
- Send WhatsApp message → Verify order created in Sheets
- Simulate M-Pesa payment → Verify payment matched

---

## Next Steps

For detailed day-by-day execution plan, see:
- [`docs/WEEK1_EXECUTION_PLAN.md`](./docs/WEEK1_EXECUTION_PLAN.md) - Comprehensive Week 1 plan
- [`docs/BUILD_PLAN.md`](./docs/BUILD_PLAN.md) - Week-by-week roadmap
- [`GETTING_STARTED.md`](./GETTING_STARTED.md) - Detailed step-by-step guide with troubleshooting


