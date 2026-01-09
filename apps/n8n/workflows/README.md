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
- `00_lookup_tenant_config.json` - **NEW** Utility workflow for tenant config lookup
- `01_classify_message_v2.json` - Native HTTP Request → Supabase
- `03_send_whatsapp_v2.json` - Native HTTP Request → WhatsApp API
- `04_send_sms_fallback_v2.json` - Native HTTP Request → SMS API
- `06_reconcile_payment_v2.json` - Native HTTP Request → Supabase + WhatsApp
- `07_send_payment_confirmation_v2.json` - Native HTTP Request → WhatsApp + Supabase
- `08_submit_to_etims.json` - **NEW** eTIMS/KRA invoice submission
- `09_multi_rail_payment.json` - **NEW** Multi-rail payment routing (M-Pesa/PesaLink/Airtel)

**Note**: Workflows 2 and 5 don't have v2 versions because they already use native nodes.

---

## Workflow Priority Order

### ✅ Workflow 0: `00_lookup_tenant_config` (Utility)
**Status**: ✅ Created  
**Purpose**: Reusable utility for tenant config lookup (multi-tenant support)  
**Input**: tenant_id (from query param) OR phone (for lookup)  
**Output**: tenant_config object with all SME configuration

**Key Features**:
- Native HTTP Request → Supabase
- Supports tenant_id from query param or phone lookup
- Returns full tenant config (WABA, ERPNext, M-Pesa, tax, payment rails)

**Why First**: All other workflows need tenant config for multi-tenant support.

---

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
- Native HTTP Request → Meta WhatsApp Business API
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

### ✅ Workflow 8: `08_submit_to_etims`
**Status**: ✅ Created  
**Purpose**: Submit invoice to KRA eTIMS/OSCU for tax compliance  
**Input**: tenant_id, invoice_id  
**Output**: kra_invoice_id, qr_code, validation_code

**Key Features**:
- Native HTTP Request → KRA OSCU endpoint
- Extracts tax config from tenant_config
- Stores QR code and KRA invoice ID in invoice record
- Automatic logging to message_logs

**Why Eighth**: Tax compliance is mandatory in Kenya. Every paid invoice must be submitted to KRA.

---

### ✅ Workflow 9: `09_multi_rail_payment`
**Status**: ✅ Created  
**Purpose**: Route payment to highest priority enabled payment rail  
**Input**: tenant_id, order_id, amount, customer_phone

---

## Copy-Paste Wins (Real-World Validated Patterns)

### Workflow 10: Order Confirmation Flow (Interakt Pattern)
**File**: `10_handle_order_with_confirmation.json`

**Pattern**: Interakt "Full Commerce Flow" - Browse → Order → Confirm → Pay

**Flow**:
1. Receives order intent from classifier
2. Creates draft order (status='pending_confirmation')
3. Sends confirmation message: "Order #001: Items + Total. Reply CONFIRM"
4. Waits for CONFIRM reply → Proceeds to payment

**Success Metric**: 6x conversion vs traditional e-commerce (Interakt data)

**Reference**: `docs/core/verified-research-findings.md` - Interakt success pattern

---

### Workflow 11: Reorder Bot (Botomatik Pattern)
**File**: `11_reorder_bot.json`

**Pattern**: Botomatik "Abandoned Cart Recovery" - 15% conversion uplift

**Flow**:
1. Daily cron (9AM - peak shopping time)
2. Finds repeat customers (last 14 days)
3. Sends: "Quick reorder? Same as last time? Reply YES"
4. If YES → Creates order with last items

**Success Metric**: 60% abandoned cart recovery rate (Botomatik data)

**Reference**: `docs/core/verified-research-findings.md` - Botomatik 15% conversion uplift

---

### Workflow 12: Status Broadcast (TechWaba Pattern)
**File**: `12_status_broadcast.json`

**Pattern**: TechWaba "Bulk Promotions" - Daily product updates

**Flow**:
1. Daily cron
2. Gets recent customers (last 30 days)
3. Formats status message: "Fresh stock! Reply ORDER"
4. Batch sends (10 at a time, respects rate limits)

**Success Metric**: Free marketing channel (Brazil spaza owners use Status)

**Reference**: `docs/core/verified-research-findings.md` - Brazil spaza Status updates

---

**Input**: tenant_id, order_id, amount, customer_phone  
**Output**: payment_request_id, rail_type

**Key Features**:
- Native HTTP Request → Payment rail APIs (M-Pesa, PesaLink, Airtel Money)
- Priority-based routing (highest priority enabled rail selected)
- Supports multiple payment rails per tenant
- Automatic fallback if primary rail fails

**Why Ninth**: Nairobi SMEs need multiple payment options. M-Pesa is primary, but PesaLink and Airtel Money provide alternatives.

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

# WhatsApp (Meta WhatsApp Business API)
WHATSAPP_ACCESS_TOKEN=your_whatsapp_access_token
WHATSAPP_APP_SECRET=your_app_secret  # For webhook signature verification
PHONE_NUMBER_ID=your_phone_number_id

# SMS (for fallback - optional)
SMS_PROVIDER=local  # Options: 'local' (default) or 'africastalking'
LOCAL_SMS_API_URL=http://localhost:3000  # For local SMS tool
LOCAL_SMS_API_KEY=your_local_api_key  # Optional, if local tool requires auth
# OR for AfricasTalking:
# SMS_PROVIDER=africastalking
# AFRICASTALKING_API_KEY=your_africastalking_api_key
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

---

## Error Handling

**Status:** ✅ Industry-standard error handling implemented in all critical workflows

### Error Handling Pattern

All critical workflows now include industry-standard error handling:

1. **Error Classification** - Errors are classified as:
   - `RETRYABLE` - Network errors, timeouts, rate limits (429, 503, ETIMEDOUT)
   - `NEEDS_REVIEW` - Validation errors, business logic errors (400, 422)
   - `CRITICAL` - Authentication errors, configuration errors (401, 403)

2. **Error Logging** - All errors are logged to Supabase `error_logs` table with:
   - Error message and stack trace
   - Error classification and severity
   - Context (operation, node, tenant_id, etc.)
   - Timestamp

3. **Retry Logic** - Retryable errors are retried with exponential backoff:
   - Base delay: 1 second
   - Max delay: 30 seconds
   - Max retries: 3-5 (depending on operation)
   - Jitter: 10% random variation

4. **Dead Letter Queue** - Failed retryable operations are added to `dead_letter_queue`:
   - Operation type and payload
   - Error message and stack trace
   - Retry count and max retries
   - Next retry timestamp

5. **Review Queue** - Payment reconciliation errors are added to `review_queue`:
   - Requires manual intervention
   - No automatic retry (payment matching is critical)

### Workflow-Specific Error Handling

**Message Classification (`01_classify_message_v2.json`):**
- Errors logged to `error_logs`
- Returns 500 error response
- No retry (validation errors should be logged, not retried)

**WhatsApp Sending (`03_send_whatsapp_v2.json`):**
- Retryable errors (429, 503, timeouts) retried with exponential backoff
- Max 3 retries
- Failed retryable operations added to DLQ
- Non-retryable errors logged and returned

**Payment Reconciliation (`06_reconcile_payment_v2.json`):**
- All errors logged to `error_logs`
- Errors added to `review_queue` for manual intervention
- Always returns 200 OK to M-Pesa (acknowledge receipt)
- No retry (payment matching requires manual review)

**Payment Confirmation (`07_send_payment_confirmation_v2.json`):**
- WhatsApp API errors retried with exponential backoff
- Database errors logged (no retry)
- Failed retryable operations added to DLQ

**SMS Fallback (`04_send_sms_fallback_v2.json`):**
- Errors logged to `error_logs`
- No retry (SMS is already a fallback)
- Error response returned to caller

### Error Handler Node Structure

Each workflow includes error handler nodes connected via "On Error" outputs:

```
HTTP Request Node
    ↓ (On Error)
Error Handler: Classify Error (Code)
    ↓
Error Handler: Log to error_logs (HTTP Request)
    ↓
Error Handler: Check Retry (Code) [if retryable]
    ↓
Error Handler: Retry Delay (Wait) [if should retry]
    ↓
Original Node (retry) OR Error Handler: Add to DLQ (HTTP Request)
```

### Monitoring Errors

**View Error Logs:**
```sql
SELECT * FROM error_logs 
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

**View Dead Letter Queue:**
```sql
SELECT * FROM dead_letter_queue 
WHERE status = 'pending'
ORDER BY created_at DESC;
```

**View Review Queue:**
```sql
SELECT * FROM review_queue 
WHERE status = 'pending'
ORDER BY created_at DESC;
```

### Troubleshooting Common Errors

**429 Rate Limit:**
- Error is retryable
- Exponential backoff will retry after delay
- If max retries exceeded, added to DLQ

**401 Unauthorized:**
- Error is critical
- Check API credentials
- No retry (authentication issue)

**503 Service Unavailable:**
- Error is retryable
- Exponential backoff will retry
- If persists, check service status

**400 Bad Request:**
- Error needs review
- Check request payload
- No retry (validation issue)

---

**Last Updated**: 2026-01-09  
**Status**: All 7 workflows created (v2 versions recommended) with industry-standard error handling  
**Next**: Test v2 workflows, monitor error logs
