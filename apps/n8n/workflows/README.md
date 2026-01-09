# n8n Workflows - Trade Facilitator

**First 7 workflows for WhatsApp-as-a-Service implementation.**

Based on [`docs/FIRST_7_WORKFLOWS.md`](../../docs/FIRST_7_WORKFLOWS.md) - priority order for solo dev building WaaS in Nairobi.

**Architecture**: See [`docs/WAAS_ARCHITECTURE.md`](../../docs/WAAS_ARCHITECTURE.md) - n8n is Layer 2 (Orchestration).

**Native Integrations**: See [`docs/NATIVE_INTEGRATIONS.md`](../../docs/NATIVE_INTEGRATIONS.md) - all workflows use native n8n nodes.

---

## Workflow Files

### Version 1 (Original - Uses Custom Services)
- `01_classify_message.json` - Message classification
- `02_check_consent.json` - Consent validation
- `03_send_whatsapp.json` - Send WhatsApp messages
- `04_send_sms_fallback.json` - SMS fallback
- `05_log_message.json` - Log messages
- `06_reconcile_payment.json` - Payment reconciliation
- `07_send_payment_confirmation.json` - Payment confirmation

### Version 2 (Refactored - Uses Native Nodes) ✅ RECOMMENDED
- `01_classify_message_v2.json` - Native HTTP Request → Supabase
- `03_send_whatsapp_v2.json` - Native HTTP Request → WhatsApp API
- `04_send_sms_fallback_v2.json` - Native HTTP Request → SMS API
- `06_reconcile_payment_v2.json` - Native HTTP Request → Supabase + WhatsApp
- `07_send_payment_confirmation_v2.json` - Native HTTP Request → WhatsApp + Supabase

**Note**: Workflows 2 and 5 don't have v2 versions because they already use native nodes.

---

## Workflow Priority Order

### ✅ Workflow 1: `01_classify_message_v2`
**Status**: ✅ Created (v2)  
**Purpose**: Classify incoming messages (first node in every workflow)  
**Input**: WhatsApp webhook payload  
**Output**: Message classification (type, channel, priority, fallback allowed)

**Key Features**:
- Native HTTP Request nodes for Supabase queries
- Business logic in Code node only
- No custom service dependencies

**Why First**: Every other workflow depends on classification.

---

### ✅ Workflow 2: `02_check_consent`
**Status**: ✅ Created (already uses native nodes)  
**Purpose**: Validate consent before sending marketing messages  
**Input**: phone, channel, purpose  
**Output**: consent_valid, consent_id

**Key Features**:
- Native HTTP Request → Supabase
- Business logic for implied vs explicit consent

**Why Second**: Protection - prevent Meta account blocks.

---

### ✅ Workflow 3: `03_send_whatsapp_v2`
**Status**: ✅ Created (v2)  
**Purpose**: Send WhatsApp message (with retry + timeout logic)  
**Input**: phone, message, message_type, priority  
**Output**: delivery_status, message_id, cost

**Key Features**:
- Native HTTP Request → WhatsApp API (SMSLeopard/Meta)
- Session vs template routing with Switch node
- Delivery receipt handling
- Automatic fallback trigger

**Why Third**: Core messaging logic. All other workflows use this.

---

### ✅ Workflow 4: `04_send_sms_fallback_v2`
**Status**: ✅ Created (v2)  
**Purpose**: Fallback to SMS when WhatsApp fails  
**Input**: phone, message, fallback_reason  
**Output**: delivery_status, sms_provider_id

**Key Features**:
- Native HTTP Request → SMS provider API
- Message formatting logic in Code node
- Automatic logging to Supabase

**Why Fourth**: Critical for reliability. WhatsApp failures = lost transactions without this.

---

### ✅ Workflow 5: `05_log_message`
**Status**: ✅ Created (already uses native nodes)  
**Purpose**: Log all messages to Supabase (audit trail)  
**Input**: All message events (sent, delivered, failed, fallback)  
**Output**: message_log_id

**Key Features**:
- Native HTTP Request → Supabase
- Automatic failure logging to daily_logs

**Why Fifth**: Audit trail is non-negotiable. Banks, partners, regulators will ask.

---

### ✅ Workflow 6: `06_reconcile_payment_v2`
**Status**: ✅ Created (v2)  
**Purpose**: Match M-Pesa payment to order (critical for trust)  
**Input**: M-Pesa webhook payload  
**Output**: payment_status, order_id (if matched)

**Key Features**:
- Native HTTP Request → Supabase for queries
- Payment matching logic in Code node
- Idempotency check (duplicate detection)
- Auto-match vs manual review routing

**Why Sixth**: Payment reconciliation is where startups die. Get this right early.

---

### ✅ Workflow 7: `07_send_payment_confirmation_v2`
**Status**: ✅ Created (v2)  
**Purpose**: Notify buyer + seller when payment confirmed  
**Input**: order_id, payment_id  
**Output**: confirmation_sent (buyer + seller)

**Key Features**:
- Native HTTP Request → WhatsApp API
- Native HTTP Request → Supabase for logging
- Parallel notifications (buyer + seller)

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

**Recommended**: Import v2 workflows (they use native nodes and are easier to maintain).

---

## Testing Workflows

### Quick Test
```bash
# Test all workflows
./scripts/test-all-workflows.sh

# Test individual workflow
node tests/n8n-workflow-tests.js

# Test integration flows
node tests/integration-test-suite.js
```

### Manual Test
```bash
# Test classify_message workflow
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

See [`tests/test-payloads.json`](../../tests/test-payloads.json) for sample payloads.

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
WHATSAPP_ACCESS_TOKEN=your_whatsapp_access_token

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

# n8n
N8N_BASE_URL=http://localhost:5678
```

---

## Workflow Dependencies

```
classify_message_v2 (1)
    ↓
check_consent (2) ← Used by send_whatsapp_v2
    ↓
send_whatsapp_v2 (3) ← Used by all messaging workflows
    ↓
send_sms_fallback_v2 (4) ← Triggered by send_whatsapp_v2 on failure
    ↓
log_message (5) ← Used by all workflows
    ↓
reconcile_payment_v2 (6) ← Triggered by M-Pesa webhook
    ↓
send_payment_confirmation_v2 (7) ← Triggered by reconcile_payment_v2
```

---

## Migration from v1 to v2

**Status**: v2 workflows ready, v1 workflows can be archived after testing.

**Migration Steps**:
1. Import v2 workflows into n8n
2. Test v2 workflows with sample data
3. Run in parallel with v1 (if needed)
4. Cutover to v2 after validation
5. Archive v1 workflows

See [`docs/MIGRATION_CHECKLIST.md`](../../docs/MIGRATION_CHECKLIST.md) for detailed migration plan.

---

## Benefits of v2 Workflows

**Before (v1 with custom services)**:
- ❌ Custom service dependencies
- ❌ More code to maintain
- ❌ Harder to debug
- ❌ Custom error handling

**After (v2 with native nodes)**:
- ✅ No custom service dependencies
- ✅ Less code to maintain (~1,200 lines removed)
- ✅ Easier to debug (n8n UI)
- ✅ Built-in error handling and retry
- ✅ Better credential management
- ✅ Visual workflow debugging

---

## Next Steps

1. **Import v2 workflows** into n8n
2. **Configure environment variables** in n8n
3. **Test workflows** with sample data (see `tests/test-payloads.json`)
4. **Run integration tests** (see `tests/integration-test-suite.js`)
5. **Deploy to production** after validation

**See [`docs/FIRST_7_WORKFLOWS.md`](../../docs/FIRST_7_WORKFLOWS.md) for detailed workflow logic.**

---

**Last Updated**: 2026-01-09  
**Status**: All 7 workflows created (v2 versions recommended)  
**Next**: Test v2 workflows, then remove old services
