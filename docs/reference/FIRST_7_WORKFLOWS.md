# First 7 n8n Workflows to Build

**Priority order for solo dev building WhatsApp-as-a-Service in Nairobi.**

Based on the WaaS architecture principles in [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md). These workflows follow the rule: **n8n = orchestration, ERPNext = truth**.

---

## Workflow 1: `classify_message`

**Purpose**: Classify incoming messages (first node in every workflow)

**Input**: WhatsApp webhook payload

**Output**: Message classification (type, channel, priority, fallback allowed)

**Logic**:
```
1. Extract: from, text, type (text/image/voice), timestamp
   ↓
2. Classify message type:
   - If contains "order|nataka|taka" → order
   - If contains "payment|paid|pesa" → payment_query
   - If contains "status|where|delivery" → status_query
   - If contains "help|support|saaidie" → support
   - Else → unknown
   ↓
3. Check user type (query ERPNext):
   - If exists in buyers → buyer
   - If exists in sellers → seller
   - Else → new_user
   ↓
4. Check conversation window (query ERPNext):
   - Last message timestamp
   - If within 24h → session_message_allowed
   - Else → template_required
   ↓
5. Determine priority:
   - order, payment_query → high
   - status_query → medium
   - support → medium
   - unknown → low
   ↓
6. Determine fallback allowed:
   - transactional (order, payment, status) → yes
   - marketing → no (respect opt-in)
   ↓
7. Output: {
     message_type: 'order',
     user_type: 'buyer',
     priority: 'high',
     session_allowed: true,
     fallback_allowed: true,
     phone: '+254700456789'
   }
```

**Why First**: Every other workflow depends on classification. Build this before anything else.

---

## Workflow 2: `send_whatsapp`

**Purpose**: Send WhatsApp message (with retry + timeout logic)

**Input**: phone, message, message_type, priority

**Output**: delivery_status, message_id, cost

**Logic**:
```
1. Check conversation window (query ERPNext):
   - If within 24h → Use session message (free)
   - Else → Use template (paid)
   ↓
2. If template required:
   - Check template exists (query template registry)
   - Validate consent (query consent table)
   - If no consent for marketing → abort, log to daily_logs
   ↓
3. Send via SMSLeopard/Meta API:
   - POST /v1/messages
   - Store request_id for tracking
   ↓
4. Wait for delivery receipt (timeout: 60 seconds)
   ↓
5. If delivered ✅:
   - Log to message_logs: status='delivered', channel='whatsapp'
   - Update ERPNext: conversations.last_message_at
   - Done
   ↓
6. If not delivered ❌ (timeout or failed):
   - Log to message_logs: status='failed', channel='whatsapp'
   - If fallback_allowed → Trigger send_sms_fallback
   - Else → Log to daily_logs: requires_review=true
```

**Why Second**: Core messaging logic. All other workflows use this.

---

## Workflow 3: `send_sms_fallback`

**Purpose**: Fallback to SMS when WhatsApp fails (Kenya reality)

**Input**: phone, message, fallback_reason

**Output**: delivery_status, sms_provider_id

**Logic**:
```
1. Check message type:
   - If transactional (order, payment, status) → Proceed
   - If marketing → Abort (respect opt-in, don't fallback)
   ↓
2. Format SMS (160 chars max):
   - Truncate if needed
   - Add "Reply HELP for support" if space allows
   ↓
3. Send via SMS provider (AfricasTalking, SMSLeopard, etc.):
   - POST /sms/send
   - Store provider_id for tracking
   ↓
4. Log to message_logs:
   - channel='sms'
   - status='sent' (SMS doesn't have delivery receipts reliably)
   - fallback_used=true
   - fallback_reason='whatsapp_timeout' or 'whatsapp_failed'
   ↓
5. Update ERPNext: conversations.last_message_at (if new conversation)
   ↓
6. Calculate cost: cost_kes = 1.00 (SMS cost)
   - Log to message_logs: cost_kes
```

**Why Third**: Critical for reliability. WhatsApp failures = lost transactions without this.

---

## Workflow 4: `log_message`

**Purpose**: Log all messages to ERPNext (audit trail)

**Input**: All message events (sent, delivered, failed, fallback)

**Output**: message_log_id

**Logic**:
```
1. Extract: phone, channel, message_type, status, message_id, etc.
   ↓
2. Insert into ERPNext: message_logs table
   - All fields from input
   - timestamp = NOW()
   ↓
3. If status = 'failed':
   - Also log to daily_logs: event_type='message_failed', requires_review=true
   ↓
4. If fallback_used = true:
   - Update original message_log: fallback_log_id = new_message_log_id
   ↓
5. Calculate cost (if not already provided):
   - WhatsApp template: 0.75 KSh
   - WhatsApp session: 0 KSh (within 24h window)
   - SMS: 1.00 KSh
   ↓
6. Update cost tracking in ERPNext (aggregate daily costs)
```

**Why Fourth**: Audit trail is non-negotiable. Banks, partners, regulators will ask.

---

## Workflow 5: `reconcile_payment`

**Purpose**: Match M-Pesa payment to order (critical for trust)

**Input**: M-Pesa webhook payload

**Output**: payment_status, order_id (if matched)

**Logic**:
```
1. Extract from webhook:
   - receipt_number, amount, phone, timestamp
   ↓
2. Query ERPNext: Find orders by phone + amount (±50 KSh tolerance)
   SELECT * FROM orders
   WHERE customer_phone = phone
   AND total_kes BETWEEN (amount - 50) AND (amount + 50)
   AND payment_status = 'pending'
   ORDER BY created_at DESC
   LIMIT 5
   ↓
3. If one match found:
   - Update ERPNext: orders.payment_status='confirmed', mpesa_ref=receipt_number
   - Insert into payments table
   - Log to audit_logs: entity_type='order', action='payment_confirmed'
   - Trigger: send_payment_confirmation (buyer + seller)
   ↓
4. If multiple matches:
   - Log to daily_logs: event_type='payment_mismatch', requires_review=true
   - Include all candidate orders in details
   - Don't auto-confirm (manual review required)
   ↓
5. If no match:
   - Log to daily_logs: event_type='orphan_payment', requires_review=true
   - Include: receipt_number, amount, phone, timestamp
   - Manual reconciliation required
   ↓
6. Always log to audit_logs: entity_type='payment', action='webhook_received'
```

**Why Fifth**: Payment reconciliation is where startups die. Get this right early.

---

## Workflow 6: `send_payment_confirmation`

**Purpose**: Notify buyer + seller when payment confirmed

**Input**: order_id, payment_id

**Output**: confirmation_sent (buyer + seller)

**Logic**:
```
1. Query ERPNext: Get order details
   - customer_phone, seller_phone, total_kes, mpesa_ref
   ↓
2. Send to buyer (transactional, no opt-in needed):
   - Template: 'payment_confirmation'
   - Variables: trade_id, amount, mpesa_receipt
   - Trigger: send_whatsapp (with fallback)
   ↓
3. Send to seller (transactional, no opt-in needed):
   - Template: 'payment_received'
   - Variables: trade_id, amount, buyer_phone
   - Trigger: send_whatsapp (with fallback)
   ↓
4. Log to message_logs: Both messages
   ↓
5. Update ERPNext: orders.payment_confirmed_at = NOW()
   ↓
6. Trigger next workflow: mark_order_ready (seller can dispatch)
```

**Why Sixth**: User trust depends on transparency. Always confirm payments.

---

## Workflow 7: `check_consent`

**Purpose**: Validate consent before sending marketing messages

**Input**: phone, channel, purpose

**Output**: consent_valid, consent_id

**Logic**:
```
1. Query ERPNext: Check consent table
   SELECT * FROM consent
   WHERE phone = phone
   AND channel = channel
   AND purpose = purpose
   AND status = 'active'
   ORDER BY timestamp DESC
   LIMIT 1
   ↓
2. If consent found:
   - Return: consent_valid=true, consent_id
   - Update: consent.last_used_at = NOW() (for tracking)
   ↓
3. If no consent:
   - If purpose = 'transactional' → consent_valid=true (implied consent)
   - If purpose = 'marketing' → consent_valid=false (explicit consent required)
   ↓
4. If consent_valid=false:
   - Log to daily_logs: event_type='consent_missing', requires_review=true
   - Abort message sending
   ↓
5. If consent_valid=true:
   - Proceed with message sending
   - Log consent usage to audit_logs
```

**Why Seventh**: Meta punishes mistakes. Consent violations = account blocks.

---

## Workflow Execution Order

**Recommended build order:**

1. ✅ `classify_message` (Foundation - needed by all)
2. ✅ `check_consent` (Protection - prevent violations)
3. ✅ `send_whatsapp` (Core messaging)
4. ✅ `send_sms_fallback` (Reliability)
5. ✅ `log_message` (Audit trail)
6. ✅ `reconcile_payment` (Trust)
7. ✅ `send_payment_confirmation` (Transparency)

**Week 1 Goal**: Build workflows 1-3 (classification, consent, WhatsApp sending)
**Week 2 Goal**: Add workflows 4-5 (logging, payment reconciliation)
**Week 3 Goal**: Add workflows 6-7 (confirmations, consent checking)

---

## Integration Points (ERPNext API)

**All workflows should use ERPNext as source of truth:**

### Query Operations (n8n → ERPNext)
```
GET /api/resource/Customer?filters=[["phone", "=", "+254700456789"]]
GET /api/resource/Sales%20Order?filters=[["customer_phone", "=", "+254700456789"], ["payment_status", "=", "pending"]]
GET /api/resource/Consent?filters=[["phone", "=", "+254700456789"], ["status", "=", "active"]]
```

### Create Operations (n8n → ERPNext)
```
POST /api/resource/Message%20Log
POST /api/resource/Audit%20Log
POST /api/resource/Daily%20Log
```

### Update Operations (n8n → ERPNext)
```
PUT /api/resource/Sales%20Order/TR20260109001
{
  "payment_status": "confirmed",
  "mpesa_ref": "QR3UQR4O"
}
```

---

## Error Handling (Every Workflow)

**Every workflow must handle:**

1. **Timeout**: External API calls (60s timeout)
2. **Retry**: Failed API calls (3 retries, exponential backoff)
3. **Fallback**: WhatsApp → SMS (if transactional)
4. **Logging**: All failures to daily_logs (requires_review=true)
5. **Idempotency**: Duplicate webhooks (check message_id first)

**Error Response Pattern**:
```
If error:
  - Log to daily_logs: event_type='workflow_error', details=error_message
  - Return: { success: false, error: error_message, requires_review: true }
  - Never throw (acknowledge webhook, log for manual review)
```

---

## Testing Each Workflow

**Test scenarios for each workflow:**

### `classify_message`
- ✅ Test with order message: "I want 2m red chiffon"
- ✅ Test with payment query: "Did you receive my payment?"
- ✅ Test with new user (not in ERPNext)
- ✅ Test with existing buyer
- ✅ Test with existing seller

### `send_whatsapp`
- ✅ Test within 24h window (session message)
- ✅ Test outside 24h window (template required)
- ✅ Test template message (requires approval)
- ✅ Test delivery receipt received
- ✅ Test timeout (no delivery receipt)
- ✅ Test failure (provider error)

### `send_sms_fallback`
- ✅ Test after WhatsApp timeout
- ✅ Test after WhatsApp failure
- ✅ Test transactional message (should fallback)
- ✅ Test marketing message (should not fallback - respect opt-in)

### `reconcile_payment`
- ✅ Test exact match (one order found)
- ✅ Test multiple matches (manual review)
- ✅ Test no match (orphan payment)
- ✅ Test amount tolerance (±50 KSh)
- ✅ Test duplicate webhook (idempotency)

---

## Cost Control (Every Workflow)

**Track costs in every workflow:**

1. **WhatsApp session message**: 0 KSh (within 24h window)
2. **WhatsApp template**: 0.75 KSh (outside 24h window)
3. **SMS**: 1.00 KSh
4. **API calls**: Minimal (n8n + ERPNext)

**Cost Logging**:
- Log to message_logs: cost_kes
- Aggregate daily costs in ERPNext
- Track cost per trade (target: < KSh 3.00 per trade)

---

## Next Steps

1. **Build workflow 1** (`classify_message`) - test thoroughly
2. **Build workflow 3** (`check_consent`) - prevent violations
3. **Build workflow 2** (`send_whatsapp`) - core messaging
4. **Build workflow 4** (`log_message`) - audit trail
5. **Build workflow 7** (`send_sms_fallback`) - reliability
6. **Build workflow 5** (`reconcile_payment`) - trust
7. **Build workflow 6** (`send_payment_confirmation`) - transparency

**Week 1 Target**: Workflows 1, 3, 2 (classification, consent, WhatsApp)
**Week 2 Target**: Workflows 4, 7 (logging, fallback)
**Week 3 Target**: Workflows 5, 6 (payment reconciliation, confirmations)

---

**Reference**: 
- **WaaS Architecture**: [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md)
- **Build Plan**: [`BUILD_PLAN.md`](./BUILD_PLAN.md)

---

**Last Updated**: 2026-01-09  
**Status**: Ready to build - workflows defined, ERPNext integration points specified

