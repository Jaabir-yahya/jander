# Test Scenarios

## Week 1 Test Cases

### Test 1: Happy Path - Text Order
**Scenario:** Customer sends text order via WhatsApp

**Steps:**
1. Send WhatsApp message: "2m red chiffon, Jane, +254700456789"
2. Expected: Order created in Google Sheets
3. Expected: Order ID generated (format: O######)
4. Expected: Confirmation message sent to customer
5. Expected: Payment status = "Pending"

**Verify:**
- [ ] Order appears in ORDERS sheet
- [ ] All fields populated correctly
- [ ] Customer receives confirmation
- [ ] Order ID is unique

---

### Test 2: Image Order (OCR)
**Scenario:** Customer sends product photo with order details

**Steps:**
1. Send WhatsApp image with text: "Order: 3m blue kitenge for Amina +254712345678"
2. Expected: Image downloaded
3. Expected: OCR extracts order text
4. Expected: Order parsed and created
5. Expected: Confirmation sent

**Verify:**
- [ ] Image processed by OCR
- [ ] Order details extracted correctly
- [ ] Order created in sheet
- [ ] Raw OCR text saved in notes

---

### Test 3: Voice Note Order (Swahili)
**Scenario:** Customer sends voice note in Swahili

**Steps:**
1. Send WhatsApp voice note: "Nataka nyuma chiffon nyekundu senti kumi, Jane, +254700456789"
2. Expected: Audio transcribed
3. Expected: Confidence > 0.7
4. Expected: Order parsed from transcription
5. Expected: Order created

**Verify:**
- [ ] Transcription accuracy
- [ ] Order details extracted
- [ ] Order created
- [ ] Confidence logged

---

### Test 4: Low Confidence Voice Note
**Scenario:** Unclear voice note (confidence < 0.7)

**Steps:**
1. Send unclear WhatsApp voice note
2. Expected: Transcription attempted
3. Expected: Confidence < 0.7
4. Expected: Logged to DAILY_LOG for review
5. Expected: Trader notified

**Verify:**
- [ ] Low confidence detected
- [ ] Logged to DAILY_LOG
- [ ] Marked as "needs_review"
- [ ] Alert sent to trader

---

### Test 5: Payment Matching
**Scenario:** Customer pays via M-Pesa

**Steps:**
1. Create order (Test 1)
2. Simulate M-Pesa payment via Daraja sandbox
3. Expected: Payment webhook received
4. Expected: Order matched by phone + amount
5. Expected: Payment status updated to "Confirmed"
6. Expected: Confirmation message sent

**Verify:**
- [ ] Payment webhook received
- [ ] Order matched correctly
- [ ] Payment status updated
- [ ] Customer receives confirmation
- [ ] M-Pesa ref saved

---

### Test 6: Payment Mismatch (No Order)
**Scenario:** Payment received but no matching order

**Steps:**
1. Simulate M-Pesa payment for amount not in system
2. Expected: Payment webhook received
3. Expected: No order match found
4. Expected: Logged to DAILY_LOG
5. Expected: Alert sent for manual review

**Verify:**
- [ ] Payment received
- [ ] No match found
- [ ] Logged to DAILY_LOG
- [ ] Marked as "Payment Mismatch"
- [ ] Alert sent

---

### Test 7: Multiple Orders Same Customer
**Scenario:** Customer has multiple pending orders

**Steps:**
1. Create 2 orders for same customer
2. Receive payment matching one order amount
3. Expected: System matches to correct order
4. Expected: Other order remains pending

**Verify:**
- [ ] Payment matched to correct order
- [ ] Amount tolerance works (±KSh 50)
- [ ] Other order unchanged
- [ ] No false matches

---

### Test 8: Offline Sync (Edge Case)
**Scenario:** Order captured offline, synced later

**Steps:**
1. Disconnect n8n from internet
2. Send WhatsApp order (SMSLeopard queues)
3. Reconnect internet
4. Expected: Queued message processed
5. Expected: Order created

**Verify:**
- [ ] Queued messages processed
- [ ] No data loss
- [ ] Order created correctly
- [ ] Timestamps accurate

---

### Test 9: Error Handling - API Down
**Scenario:** SMSLeopard API temporarily unavailable

**Steps:**
1. Simulate SMSLeopard API failure
2. Send order message
3. Expected: Error logged to DAILY_LOG
4. Expected: Retry mechanism (if implemented)
5. Expected: Alert sent

**Verify:**
- [ ] Error caught and logged
- [ ] No data loss
- [ ] Alert sent
- [ ] Recovery when API back

---

### Test 10: End-to-End Flow
**Scenario:** Complete order cycle

**Steps:**
1. Customer sends text order
2. Order created and confirmed
3. Customer pays via M-Pesa
4. Payment matched automatically
5. Dispatch status updated manually
6. Delivery confirmation sent

**Verify:**
- [ ] All steps automated correctly
- [ ] No manual intervention needed (except dispatch)
- [ ] All confirmations sent
- [ ] Order statuses updated
- [ ] Complete audit trail

---

## Test Data

### Sample Orders
1. "2m red chiffon, Jane, +254700456789"
2. "3m blue kitenge, Amina, +254712345678"
3. "5m white cotton, John, +254723456789"

### Sample Payments
- Amount: KSh 1000, Phone: +254700456789 → Match order #1
- Amount: KSh 1500, Phone: +254712345678 → Match order #2
- Amount: KSh 500, Phone: +254799999999 → No match (test mismatch)

---

## Success Criteria

Week 1 is successful if:
- [ ] All 10 test cases pass
- [ ] Payment match rate > 90%
- [ ] Zero data loss
- [ ] All automations working
- [ ] End-to-end flow operational



