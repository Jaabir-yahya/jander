# Integration Tests

**Comprehensive test cases for all integrations to ensure production readiness.**

Each integration must pass these tests before going to production. Tests are organized by integration and priority.

---

## Test Organization

**Priority Levels:**
- **P0 (Critical)**: Must pass before Stage 1 completion
- **P1 (High)**: Must pass before Stage 2 completion
- **P2 (Medium)**: Must pass before Stage 3 completion
- **P3 (Low)**: Nice to have, implement during Stage 4+

---

## 1. SMSLeopard / Meta WhatsApp Business API Tests

### P0: Webhook Verification

**Test 1.1: Webhook Signature Verification**
- **Scenario**: Verify webhook requests are from SMSLeopard/Meta
- **Steps**:
  1. Receive webhook request with signature header
  2. Verify HMAC-SHA256 signature matches payload
  3. Reject if signature invalid
- **Expected**: Invalid signatures rejected, valid signatures accepted
- **Status**: ❌ Not implemented

**Test 1.2: Webhook Verification Endpoint (GET)**
- **Scenario**: SMSLeopard/Meta verifies webhook endpoint
- **Steps**:
  1. Receive GET request with `hub.verify_token` and `hub.challenge`
  2. Verify `hub.verify_token` matches expected token
  3. Return `hub.challenge` if valid
- **Expected**: Returns challenge token on valid verification
- **Status**: ⚠️ Partial (basic verification exists)

**Test 1.3: Idempotency Key Handling**
- **Scenario**: Prevent duplicate processing of same message
- **Steps**:
  1. Receive webhook with idempotency key
  2. Check if message_id already processed
  3. Return cached response if duplicate
  4. Process only if new
- **Expected**: Duplicate webhooks return cached response, no duplicate processing
- **Status**: ❌ Not implemented

---

### P0: Message Delivery

**Test 1.4: Send Text Message**
- **Scenario**: Send text message via API
- **Steps**:
  1. Send text message via API
  2. Verify message_id returned
  3. Check delivery status webhook received
  4. Verify message delivered to customer
- **Expected**: Message sent successfully, delivery confirmed
- **Status**: ✅ Implemented (basic)

**Test 1.5: Send Template Message**
- **Scenario**: Send pre-approved template message
- **Steps**:
  1. Send template message with variables
  2. Verify template approved and valid
  3. Check message_id returned
  4. Verify delivery status webhook
- **Expected**: Template message sent, delivery confirmed
- **Status**: ⚠️ Partial (templates not yet approved)

**Test 1.6: Delivery Status Webhooks**
- **Scenario**: Receive delivery status updates
- **Steps**:
  1. Send message
  2. Wait for delivery status webhook
  3. Verify status: sent → delivered → read (if applicable)
  4. Log status transitions
- **Expected**: All status transitions received and logged
- **Status**: ❌ Not implemented

**Test 1.7: Message Status Query**
- **Scenario**: Query message status by message_id
- **Steps**:
  1. Send message, get message_id
  2. Query message status via API
  3. Verify status matches webhook updates
  4. Handle message not found error
- **Expected**: Status query returns accurate status
- **Status**: ❌ Not implemented

---

### P0: Error Handling

**Test 1.8: Rate Limit Handling**
- **Scenario**: Handle rate limit errors gracefully
- **Steps**:
  1. Send messages rapidly to trigger rate limit
  2. Receive 429 error with Retry-After header
  3. Queue message for retry after Retry-After duration
  4. Retry after delay
- **Expected**: Rate limits handled gracefully, messages queued and retried
- **Status**: ❌ Not implemented

**Test 1.9: Invalid Template Error**
- **Scenario**: Handle invalid template errors
- **Steps**:
  1. Send message with invalid template name
  2. Receive error response
  3. Log error with details
  4. Notify trader of template issue
- **Expected**: Invalid template errors caught, logged, trader notified
- **Status**: ❌ Not implemented

**Test 1.10: Media Upload Error**
- **Scenario**: Handle media upload failures
- **Steps**:
  1. Upload oversized image file
  2. Receive error response
  3. Log error with details
  4. Notify trader of file size limit
- **Expected**: File size errors caught, logged, trader notified
- **Status**: ❌ Not implemented

---

### P1: Retry Logic

**Test 1.11: Webhook Retry Mechanism**
- **Scenario**: SMSLeopard retries failed webhooks
- **Steps**:
  1. Temporarily fail webhook endpoint (return 500)
  2. Verify SMSLeopard retries with exponential backoff
  3. Restore endpoint, verify retry succeeds
  4. Check idempotency (no duplicate processing)
- **Expected**: Failed webhooks retried, no duplicate processing
- **Status**: ❌ Not implemented

**Test 1.12: Message Send Retry**
- **Scenario**: Retry failed message sends
- **Steps**:
  1. Simulate API failure (network timeout)
  2. Retry message send with exponential backoff
  3. Verify success after retry
  4. Verify no duplicate messages sent
- **Expected**: Failed sends retried, no duplicate messages
- **Status**: ❌ Not implemented

---

### P1: Media Handling

**Test 1.13: Image Upload and Download**
- **Scenario**: Upload image, receive via webhook, download
- **Steps**:
  1. Customer sends image via WhatsApp
  2. Receive webhook with image URL
  3. Download image before URL expires
  4. Process image (OCR, save to storage)
- **Expected**: Images uploaded, received, downloaded successfully
- **Status**: ⚠️ Partial (basic image handling exists)

**Test 1.14: PDF Upload (Invoice)**
- **Scenario**: Send PDF invoice via WhatsApp
- **Steps**:
  1. Generate invoice PDF
  2. Upload PDF to media API
  3. Send message with PDF attachment
  4. Verify customer receives PDF
- **Expected**: PDF uploaded, sent, received successfully
- **Status**: ❌ Not implemented

---

## 2. n8n Tests

### P0: Webhook Receiver

**Test 2.1: Webhook Endpoint Verification**
- **Scenario**: n8n webhook endpoint verifies requests
- **Steps**:
  1. Configure webhook endpoint with verify_token
  2. Send GET request with verify_token
  3. Verify challenge returned
  4. Test invalid token rejected
- **Expected**: Valid tokens return challenge, invalid tokens rejected
- **Status**: ⚠️ Partial (basic verification exists)

**Test 2.2: Webhook Payload Processing**
- **Scenario**: Process webhook payload correctly
- **Steps**:
  1. Receive webhook payload from SMSLeopard
  2. Extract message data (text, media, metadata)
  3. Route to appropriate workflow
  4. Log webhook receipt
- **Expected**: Payload processed correctly, workflow triggered
- **Status**: ✅ Implemented (basic)

---

### P0: Error Handling

**Test 2.3: Workflow Error Handling**
- **Scenario**: Handle workflow execution errors
- **Steps**:
  1. Trigger workflow with invalid data
  2. Verify error caught in try/catch node
  3. Log error with context
  4. Send error notification
  5. Workflow doesn't crash
- **Expected**: Errors caught, logged, notified, workflow continues
- **Status**: ❌ Not implemented

**Test 2.4: API Error Retry**
- **Scenario**: Retry failed API calls automatically
- **Steps**:
  1. Configure HTTP node with retry logic
  2. Simulate API failure (500 error)
  3. Verify retry with exponential backoff
  4. Verify success after retry
- **Expected**: Failed API calls retried automatically
- **Status**: ❌ Not implemented

---

### P1: Rate Limiting

**Test 2.5: Workflow Rate Limiting**
- **Scenario**: Limit workflow execution rate
- **Steps**:
  1. Configure rate limit (e.g., 10 requests/minute)
  2. Trigger workflow rapidly (20 requests)
  3. Verify first 10 execute, rest queued
  4. Verify queued requests execute after delay
- **Expected**: Rate limits enforced, excess requests queued
- **Status**: ❌ Not implemented

---

### P1: Database Operations

**Test 2.6: Supabase CRUD Operations**
- **Scenario**: Create, read, update, delete in Supabase
- **Steps**:
  1. Create order via Supabase node
  2. Read order by ID
  3. Update order status
  4. Delete test order
- **Expected**: All CRUD operations succeed
- **Status**: ❌ Not implemented (Supabase not yet integrated)

**Test 2.7: Google Sheets CRUD Operations**
- **Scenario**: Create, read, update in Google Sheets
- **Steps**:
  1. Create order row in Sheets
  2. Read order row by ID
  3. Update order status
  4. Verify data integrity
- **Expected**: All Sheet operations succeed, data integrity maintained
- **Status**: ✅ Implemented (basic)

---

### P2: Workflow Versioning

**Test 2.8: Workflow Export/Import**
- **Scenario**: Export workflow, import to another instance
- **Steps**:
  1. Export workflow as JSON
  2. Import workflow to test instance
  3. Verify workflow structure intact
  4. Test workflow execution
- **Expected**: Workflow exported, imported, executes correctly
- **Status**: ❌ Not implemented

---

## 3. Supabase Tests

### P0: Data Integrity

**Test 3.1: Row-Level Security (RLS)**
- **Scenario**: Traders can only see own data
- **Steps**:
  1. Create two traders with separate data
  2. Query orders as Trader A
  3. Verify only Trader A's orders returned
  4. Verify Trader B's orders not accessible
- **Expected**: RLS policies enforced, data isolated
- **Status**: ❌ Not implemented (RLS not yet configured)

**Test 3.2: Foreign Key Constraints**
- **Scenario**: Prevent orphaned records
- **Steps**:
  1. Attempt to create order with invalid trader_id
  2. Verify foreign key constraint prevents creation
  3. Create valid trader, then create order
  4. Verify order created successfully
- **Expected**: Invalid foreign keys rejected, valid relationships allowed
- **Status**: ❌ Not implemented

**Test 3.3: Unique Constraints**
- **Scenario**: Prevent duplicate order_ids
- **Steps**:
  1. Create order with order_id "O001"
  2. Attempt to create another order with same order_id
  3. Verify unique constraint prevents duplicate
  4. Verify error message clear
- **Expected**: Duplicate order_ids rejected, error message clear
- **Status**: ❌ Not implemented

---

### P0: Realtime Subscriptions

**Test 3.4: Realtime Order Creation**
- **Scenario**: Subscribe to new orders, receive updates
- **Steps**:
  1. Subscribe to orders table via Realtime
  2. Create new order in another client
  3. Verify subscription receives new order event
  4. Verify order data complete
- **Expected**: Realtime subscription receives new orders instantly
- **Status**: ❌ Not implemented (Realtime not yet configured)

---

### P1: Database Migrations

**Test 3.5: Migration Up/Down**
- **Scenario**: Apply and rollback migrations
- **Steps**:
  1. Create migration file
  2. Apply migration (up)
  3. Verify schema changes applied
  4. Rollback migration (down)
  5. Verify schema reverted
- **Expected**: Migrations apply and rollback correctly
- **Status**: ❌ Not implemented

**Test 3.6: Migration Ordering**
- **Scenario**: Migrations apply in correct order
- **Steps**:
  1. Create two migrations (A, B) where B depends on A
  2. Apply migrations
  3. Verify B applied after A
  4. Verify dependencies satisfied
- **Expected**: Migrations apply in dependency order
- **Status**: ❌ Not implemented

---

### P1: Backup & Recovery

**Test 3.7: Database Backup**
- **Scenario**: Automated daily backup runs
- **Steps**:
  1. Verify backup scheduled (daily at 2 AM)
  2. Trigger manual backup
  3. Verify backup file created
  4. Verify backup contains all data
- **Expected**: Backups created automatically, data complete
- **Status**: ❌ Not implemented

**Test 3.8: Database Restore**
- **Scenario**: Restore database from backup
- **Steps**:
  1. Create test data
  2. Create backup
  3. Delete test data
  4. Restore from backup
  5. Verify test data restored
- **Expected**: Database restored successfully, data intact
- **Status**: ❌ Not implemented

---

## 4. M-Pesa Daraja API Tests

### P0: STK Push

**Test 4.1: STK Push Initiation**
- **Scenario**: Initiate STK push payment request
- **Steps**:
  1. Call STK Push API with phone, amount, order_id
  2. Verify checkout_request_id returned
  3. Verify customer receives STK push prompt
  4. Log STK push initiation
- **Expected**: STK push initiated, customer receives prompt
- **Status**: ⚠️ Partial (STK push not yet tested end-to-end)

**Test 4.2: STK Push Callback**
- **Scenario**: Receive payment confirmation via callback
- **Steps**:
  1. Initiate STK push
  2. Customer completes payment
  3. Receive callback webhook
  4. Verify callback signature
  5. Extract payment details (receipt, amount, phone)
  6. Match to order
- **Expected**: Callback received, verified, payment matched
- **Status**: ❌ Not implemented

**Test 4.3: STK Push Timeout**
- **Scenario**: Handle STK push timeout
- **Steps**:
  1. Initiate STK push
  2. Wait for timeout (customer doesn't pay)
  3. Receive timeout callback
  4. Retry STK push or escalate
- **Expected**: Timeout handled, retry or escalation triggered
- **Status**: ❌ Not implemented

---

### P0: Payment Matching

**Test 4.4: Payment Matching by Phone + Amount**
- **Scenario**: Match payment to order by phone and amount
- **Steps**:
  1. Create order for customer +254700456789, amount 1000
  2. Receive payment callback: phone +254700456789, amount 1000
  3. Match payment to order
  4. Update order payment_status
- **Expected**: Payment matched correctly, order updated
- **Status**: ⚠️ Partial (basic matching logic exists)

**Test 4.5: Payment Matching with Tolerance**
- **Scenario**: Match payment within amount tolerance
- **Steps**:
  1. Create order for amount 1000
  2. Receive payment: amount 995 (within ±50 tolerance)
  3. Match payment to order
  4. Verify order updated
- **Expected**: Payment matched within tolerance
- **Status**: ❌ Not implemented (tolerance not yet configured)

**Test 4.6: Payment Mismatch Handling**
- **Scenario**: Handle payment without matching order
- **Steps**:
  1. Receive payment callback with no matching order
  2. Log to DAILY_LOG
  3. Notify trader for manual review
  4. Store payment for later matching
- **Expected**: Mismatch logged, trader notified, payment stored
- **Status**: ⚠️ Partial (basic logging exists)

---

### P0: Webhook Security

**Test 4.7: Webhook Signature Verification**
- **Scenario**: Verify Daraja webhook signatures
- **Steps**:
  1. Receive callback webhook
  2. Extract signature from header
  3. Verify HMAC signature matches payload
  4. Reject if invalid
- **Expected**: Invalid signatures rejected, valid signatures accepted
- **Status**: ❌ Not implemented

---

### P1: Transaction Queries

**Test 4.8: Query Transaction Status**
- **Scenario**: Query payment status by receipt number
- **Steps**:
  1. Complete payment, get receipt number
  2. Query transaction status via API
  3. Verify status matches callback data
  4. Handle transaction not found error
- **Expected**: Transaction status queried accurately
- **Status**: ❌ Not implemented

---

### P1: Retry Logic

**Test 4.9: STK Push Retry**
- **Scenario**: Retry failed STK pushes
- **Steps**:
  1. Initiate STK push, customer doesn't pay
  2. Wait 5 minutes
  3. Retry STK push
  4. Wait 10 minutes, retry again if needed
  5. Escalate after max attempts
- **Expected**: STK push retried with delays, escalated if needed
- **Status**: ❌ Not implemented

---

## 5. Google Cloud Speech-to-Text Tests

### P1: Transcription Accuracy

**Test 5.1: English Transcription**
- **Scenario**: Transcribe English voice note
- **Steps**:
  1. Send English voice note: "I want 2 meters red chiffon"
  2. Call Speech-to-Text API
  3. Verify transcription accurate
  4. Verify confidence > 0.8
- **Expected**: Transcription accurate, high confidence
- **Status**: ❌ Not implemented

**Test 5.2: Swahili Transcription**
- **Scenario**: Transcribe Swahili voice note
- **Steps**:
  1. Send Swahili voice note: "Nataka nyuma chiffon nyekundu senti kumi"
  2. Call Speech-to-Text API with sw-KE language code
  3. Verify transcription accurate
  4. Verify confidence > 0.7
- **Expected**: Swahili transcription accurate, acceptable confidence
- **Status**: ❌ Not implemented

**Test 5.3: Auto-Detect Language**
- **Scenario**: Auto-detect language for mixed/Sheng
- **Steps**:
  1. Send mixed English/Swahili voice note
  2. Call API with auto-detect enabled
  3. Verify language detected correctly
  4. Verify transcription reasonable
- **Expected**: Language auto-detected, transcription usable
- **Status**: ❌ Not implemented

---

### P1: Error Handling

**Test 5.4: Low Confidence Handling**
- **Scenario**: Handle low-confidence transcriptions
- **Steps**:
  1. Send unclear voice note
  2. Receive transcription with confidence < 0.7
  3. Flag for manual review
  4. Log to DAILY_LOG
- **Expected**: Low confidence flagged, logged, routed to review
- **Status**: ❌ Not implemented

**Test 5.5: Audio Format Conversion**
- **Scenario**: Convert OGG/AMR to WAV
- **Steps**:
  1. Receive WhatsApp voice note (OGG format)
  2. Convert to WAV format
  3. Send to Speech-to-Text API
  4. Verify transcription successful
- **Expected**: Format converted, transcription successful
- **Status**: ❌ Not implemented

---

## 6. Google Cloud Vision API (OCR) Tests

### P1: Text Extraction

**Test 6.1: English Text OCR**
- **Scenario**: Extract English text from image
- **Steps**:
  1. Send image with English text: "Order: 2m red chiffon, Jane, +254700456789"
  2. Call Vision API OCR
  3. Verify text extracted accurately
  4. Verify confidence > 0.8
- **Expected**: Text extracted accurately, high confidence
- **Status**: ❌ Not implemented

**Test 6.2: Handwritten Text OCR**
- **Scenario**: Extract handwritten order notes
- **Steps**:
  1. Send image with handwritten text
  2. Call Vision API with handwritten text detection
  3. Verify text extracted (may have lower accuracy)
  4. Flag for manual review if confidence low
- **Expected**: Handwritten text extracted, flagged if low confidence
- **Status**: ❌ Not implemented

---

### P1: Error Handling

**Test 6.3: Image Quality Detection**
- **Scenario**: Detect and handle low-quality images
- **Steps**:
  1. Send blurry/low-quality image
  2. Call Vision API
  3. Receive low confidence score
  4. Flag for manual review
- **Expected**: Low quality detected, flagged for review
- **Status**: ❌ Not implemented

---

## Test Execution

### Running Tests

**Manual Testing:**
```bash
# Test webhook verification
curl -X GET "https://your-webhook-url.com/webhook?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=CHALLENGE"

# Test message send
curl -X POST "https://api.smsleopard.co.ke/v1/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": "+254700456789", "message": "Test message"}'
```

**Automated Testing:**
- Use n8n test workflows for integration testing
- Use Postman collections for API testing
- Use Jest/Playwright for end-to-end testing (future)

### Test Status Tracking

Update test status in this file as tests are implemented:
- ✅ Implemented and passing
- ⚠️ Partial implementation
- ❌ Not implemented

---

## Success Criteria

**Stage 1 Complete When:**
- ✅ All P0 tests passing for SMSLeopard, n8n, M-Pesa
- ✅ At least 80% of critical capabilities verified

**Stage 2 Complete When:**
- ✅ All P1 tests passing
- ✅ Error handling and retry logic verified

**Stage 3 Complete When:**
- ✅ All P2 tests passing
- ✅ Database operations fully tested

---

**Last Updated**: 2026-01-09  
**Status**: Test cases defined, implementation in progress  
**Next Review**: End of Week 1 (P0 tests verification)

