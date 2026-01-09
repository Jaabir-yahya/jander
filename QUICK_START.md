# Quick Start - Tomorrow's Checklist

**One-page quick reference for tomorrow.**

---

## ✅ Step-by-Step (2-3 hours)

### 1. Supabase (15 min)
- Sign up: https://supabase.com
- Create project: `jander-trade-facilitator`
- Copy: Project URL, Service Role Key, Anon Key
- Run migrations: Copy `apps/supabase/migrations/*.sql` → Paste in SQL Editor → Run

### 2. SMSLeopard WhatsApp (30-60 min)
- Sign up: https://smsleopard.co.ke/whatsapp-business.html
- Get approved (may take 24-48 hours)
- Copy: API Token, Phone Number ID, Generate Verify Token

### 3. SMS Provider (15-30 min)
- Use SMSLeopard SMS (same account) OR AfricasTalking
- Copy: API Key, Register Sender ID: `TRADEFAC`

### 4. M-Pesa Daraja Sandbox (30-60 min)
- Sign up: https://developer.safaricom.co.ke
- Create app: `jander-trade-facilitator`
- Copy: Consumer Key, Secret, Shortcode, Passkey

### 5. Environment Variables (10 min)
```bash
cd apps/whatsapp-business
cp .sample.env .env
# Fill in all values from steps 1-4
```

### 6. Test Services (5 min)
```bash
cd apps/whatsapp-business
node -e "require('./services/trade-facilitator.js'); console.log('✅ OK');"
```

### 7. Setup n8n (15 min)
```bash
npm install -g n8n
n8n start
# Open http://localhost:5678
# Import workflows: apps/n8n/workflows/01_*.json, 02_*.json, 05_*.json, 06_*.json
# Add env vars in n8n settings
```

### 8. Test Workflow (10 min)
```bash
curl -X POST http://localhost:5678/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"message": {"id": "test", "from": "+254700456789", "type": "text", "text": {"body": "I want 2m red chiffon"}}}'
```

### 9. Configure Webhook (15 min)
- SMSLeopard dashboard → Webhooks → Add
- URL: `http://your-domain.com:5678/webhook/whatsapp` (or ngrok URL)
- Verify Token: Same as `.env`

---

## 📋 Credentials Checklist

**Save these values:**

- [ ] Supabase: URL, Service Role Key, Anon Key
- [ ] SMSLeopard: API Token, Phone Number ID, Verify Token
- [ ] SMS: API Key, Sender ID
- [ ] M-Pesa: Consumer Key, Secret, Shortcode, Passkey

**All go into**: `apps/whatsapp-business/.env`

---

## 🚀 Quick Commands

```bash
# Start n8n
n8n start

# Test database
cd apps/whatsapp-business
node -e "require('dotenv').config(); const {createClient} = require('@supabase/supabase-js'); const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY); db.from('buyers').select('count').then(r => console.log('✅ DB OK'));"

# Test workflow
curl -X POST http://localhost:5678/webhook/whatsapp -H "Content-Type: application/json" -d '{"message": {"id": "test", "from": "+254700456789", "type": "text", "text": {"body": "test"}}}'
```

---

## 📖 Full Guide

See `TOMORROW_ACTION_PLAN.md` for detailed instructions.

---

**Time**: 2-3 hours  
**Goal**: Credentials + migrations + test workflows 1-2, 5-6

