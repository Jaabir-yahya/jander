# n8n Workflows - Trade Facilitator

**First 7 workflows for WhatsApp-as-a-Service implementation.**

Based on [`docs/FIRST_7_WORKFLOWS.md`](../../docs/FIRST_7_WORKFLOWS.md) - priority order for solo dev building WaaS in Nairobi.

**Architecture**: See [`docs/WAAS_ARCHITECTURE.md`](../../docs/WAAS_ARCHITECTURE.md) - n8n is Layer 2 (Orchestration).

---

## Workflow Priority Order

### ✅ Workflow 1: `01_classify_message`
**Status**: ✅ Created  
**Purpose**: Classify incoming messages (first node in every workflow)  
**Input**: WhatsApp webhook payload  
**Output**: Message classification (type, channel, priority, fallback allowed)

**Logic**:
1. Extract message data (from, text, type, timestamp)
2. Classify message type (order, payment_query, status_query, support, unknown)
3. Check user type (query Supabase: buyer, seller, new_user)
4. Check conversation window (24h from last message)
5. Determine priority (high, medium, low)
6. Determine fallback allowed (transactional → yes, marketing → no)

**Why First**: Every other workflow depends on classification.

---

### ✅ Workflow 2: `02_check_consent`
**Status**: ✅ Created  
**Purpose**: Validate consent before sending marketing messages  
**Input**: phone, channel, purpose  
**Output**: consent_valid, consent_id

**Logic**:
1. Query Supabase consent table
2. If consent found → valid
3. If no consent:
   - Transactional → implied consent (valid)
   - Marketing → explicit consent required (invalid, log to daily_logs)

**Why Second**: Protection - prevent Meta account blocks.

---

### ⏳ Workflow 3: `03_send_whatsapp`
**Status**: ⏳ Pending (needs WhatsApp API integration)  
**Purpose**: Send WhatsApp message (with retry + timeout logic)  
**Input**: phone, message, message_type, priority  
**Output**: delivery_status, message_id, cost

**Logic**:
1. Check conversation window (query Supabase)
2. If within 24h → Use session message (free)
3. If outside 24h → Use template (paid)
4. If template required → Check consent
5. Send via SMSLeopard/Meta API
6. Wait for delivery receipt (timeout: 60 seconds)
7. If delivered → Log to message_logs
8. If failed → Trigger send_sms_fallback (if fallback_allowed)

**Why Third**: Core messaging logic. All other workflows use this.

**Blocked By**: WhatsApp API credentials needed (human intervention)

---

### ⏳ Workflow 4: `04_send_sms_fallback`
**Status**: ⏳ Pending (needs SMS provider integration)  
**Purpose**: Fallback to SMS when WhatsApp fails  
**Input**: phone, message, fallback_reason  
**Output**: delivery_status, sms_provider_id

**Logic**:
1. Check message type (transactional → proceed, marketing → abort)
2. Format SMS (160 chars max)
3. Send via SMS provider (SMSLeopard/AfricasTalking)
4. Log to message_logs (fallback_used=true)

**Why Fourth**: Critical for reliability. WhatsApp failures = lost transactions without this.

**Blocked By**: SMS provider API credentials needed (human intervention)

---

### ⏳ Workflow 5: `05_log_message`
**Status**: ⏳ Pending  
**Purpose**: Log all messages to Supabase (audit trail)  
**Input**: All message events (sent, delivered, failed, fallback)  
**Output**: message_log_id

**Logic**:
1. Extract message data
2. Insert into Supabase: message_logs table
3. If status = 'failed' → Also log to daily_logs
4. Calculate cost (WhatsApp template: 0.75 KSh, SMS: 1.00 KSh)
5. Update cost tracking

**Why Fifth**: Audit trail is non-negotiable. Banks, partners, regulators will ask.

---

### ⏳ Workflow 6: `06_reconcile_payment`
**Status**: ⏳ Pending  
**Purpose**: Match M-Pesa payment to order (critical for trust)  
**Input**: M-Pesa webhook payload  
**Output**: payment_status, order_id (if matched)

**Logic**:
1. Extract: receipt_number, amount, phone, timestamp
2. Query Supabase: Find orders by phone + amount (±50 KSh tolerance)
3. If one match → Update order: payment_status='confirmed'
4. If multiple matches → Log to daily_logs (manual review)
5. If no match → Log to daily_logs (orphan payment)

**Why Sixth**: Payment reconciliation is where startups die. Get this right early.

---

### ⏳ Workflow 7: `07_send_payment_confirmation`
**Status**: ⏳ Pending  
**Purpose**: Notify buyer + seller when payment confirmed  
**Input**: order_id, payment_id  
**Output**: confirmation_sent (buyer + seller)

**Logic**:
1. Query Supabase: Get order details
2. Send to buyer (template: 'payment_confirmation')
3. Send to seller (template: 'payment_received')
4. Log to message_logs
5. Update order: payment_confirmed_at

**Why Seventh**: User trust depends on transparency. Always confirm payments.

---

## Importing Workflows

1. Open n8n (http://localhost:5678 or cloud.n8n.io)
2. Click "Workflows" → "Import from File"
3. Select JSON file from this folder
4. Review and adjust node configurations:
   - Update environment variables (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
   - Update webhook URLs
   - Test with sample data
5. Activate workflow

---

## Environment Variables Required

All workflows require these environment variables in n8n:

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# WhatsApp
WHATSAPP_PROVIDER=smsleopard
SMSLEOPARD_TOKEN=your_smsleopard_token
PHONE_NUMBER_ID=your_phone_number_id

# SMS (for fallback)
SMS_PROVIDER=smsleopard
SMSLEOPARD_API_KEY=your_smsleopard_api_key
SMS_SENDER_ID=TRADEFAC

# M-Pesa
DARAJA_BASE_URL=https://sandbox.safaricom.co.ke
DARAJA_CONSUMER_KEY=your_consumer_key
DARAJA_CONSUMER_SECRET=your_consumer_secret
MPESA_SHORTCODE=your_shortcode
MPESA_PASSKEY=your_passkey
```

---

## Testing Workflows

### Test classify_message

```bash
# Send test webhook
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

### Test check_consent

```bash
# Trigger workflow with test data
# In n8n: Use "Manual Trigger" node with:
{
  "phone": "+254700456789",
  "channel": "whatsapp",
  "purpose": "marketing"
}
```

---

## Workflow Dependencies

```
classify_message (1)
    ↓
check_consent (2) ← Used by send_whatsapp
    ↓
send_whatsapp (3) ← Used by all messaging workflows
    ↓
send_sms_fallback (4) ← Triggered by send_whatsapp on failure
    ↓
log_message (5) ← Used by all workflows
    ↓
reconcile_payment (6) ← Triggered by M-Pesa webhook
    ↓
send_payment_confirmation (7) ← Triggered by reconcile_payment
```

---

## Next Steps

1. **Import workflows 1-2** (classify_message, check_consent)
2. **Configure environment variables** in n8n
3. **Test workflows** with sample data
4. **Build workflows 3-7** (requires API credentials - human intervention needed)

**See [`docs/FIRST_7_WORKFLOWS.md`](../../docs/FIRST_7_WORKFLOWS.md) for detailed workflow logic.**

---

**Last Updated**: 2026-01-09  
**Status**: Workflows 1-2 created, workflows 3-7 pending API credentials

