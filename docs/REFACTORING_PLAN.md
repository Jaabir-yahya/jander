# Refactoring Plan - Native Integrations

**Migration plan from custom services to native n8n integrations.**

---

## 🎯 Goal

Replace custom API wrapper services with n8n native nodes, keeping only business logic services.

---

## 📋 Services to Refactor

### Keep (Business Logic)
- ✅ `trade-facilitator.js` - Complex orchestration logic
- ✅ `order-parser.js` - Complex parsing logic (Swahili, English, etc.)
- ✅ `conversation-tracker.js` - Business logic for 24h windows
- ✅ `escrow-manager.js` - Business logic for payment escrow

### Remove (API Wrappers → Use Native Nodes)
- ❌ `graph-api-trade-facilitator.js` → Use n8n HTTP Request node
- ❌ `erpnext-bridge.js` → Use n8n HTTP Request node (ERPNext REST API)
- ❌ `mpesa-api.js` → Use n8n HTTP Request node (M-Pesa Daraja API)
- ❌ `message-logger.js` → Use n8n HTTP Request node (Supabase REST API)
- ❌ `payment-reconciler.js` → Use n8n HTTP Request node (Supabase REST API)
- ❌ `sms-provider.js` → Use n8n HTTP Request node (SMS provider API)

---

## 🔄 Migration Steps

### Step 1: Update Workflows (Priority 1)

**Update all workflows to use native HTTP Request nodes:**

1. **Workflow 1: classify_message**
   - ✅ Already uses HTTP Request for Supabase
   - ✅ Keep as-is

2. **Workflow 2: check_consent**
   - ✅ Already uses HTTP Request for Supabase
   - ✅ Keep as-is

3. **Workflow 3: send_whatsapp**
   - ⏳ Replace custom service call with HTTP Request node
   - ✅ Example: `03_send_whatsapp_native.json` created
   - ⏳ Update to use this pattern

4. **Workflow 4: send_sms_fallback**
   - ⏳ Replace custom service call with HTTP Request node
   - ⏳ Use SMS provider API directly

5. **Workflow 5: log_message**
   - ✅ Already uses HTTP Request for Supabase
   - ✅ Keep as-is

6. **Workflow 6: reconcile_payment**
   - ✅ Already uses HTTP Request for Supabase
   - ✅ Keep as-is

7. **Workflow 7: send_payment_confirmation**
   - ⏳ Replace custom service call with HTTP Request node
   - ⏳ Use WhatsApp API directly

---

### Step 2: Update Services (Priority 2)

**Remove API wrapper services, keep business logic:**

1. **Remove** `graph-api-trade-facilitator.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

2. **Remove** `erpnext-bridge.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

3. **Remove** `mpesa-api.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

4. **Remove** `message-logger.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

5. **Remove** `payment-reconciler.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

6. **Remove** `sms-provider.js`
   - Functionality moved to n8n HTTP Request nodes
   - No code references remain

**Keep**:
- `trade-facilitator.js` - Update to use HTTP Request nodes internally (or remove if all logic in n8n)
- `order-parser.js` - Keep (complex parsing logic)
- `conversation-tracker.js` - Keep (business logic)
- `escrow-manager.js` - Keep (business logic)

---

### Step 3: Update Documentation (Priority 3)

1. **Update** `ARCHITECTURE.md`
   - Remove references to API wrapper services
   - Add native integrations section

2. **Update** `WAAS_ARCHITECTURE.md`
   - Update Layer 2 (Orchestration) to reflect native nodes
   - Remove custom service references

3. **Update** `INTEGRATION_CAPABILITIES_MATRIX.md`
   - Add native integration capabilities
   - Update implementation notes

4. **Create** `NATIVE_INTEGRATIONS.md` ✅ (Done)

---

## ✅ Benefits

**Before (Custom Services)**:
- 6 API wrapper services to maintain
- Custom error handling
- Custom retry logic
- More testing needed
- Harder to debug

**After (Native Nodes)**:
- 0 API wrapper services
- Built-in error handling
- Built-in retry logic
- Less testing needed
- Easier to debug (n8n UI)
- Better credential management
- Visual workflow debugging

---

## 📊 Progress Tracking

### Workflows
- [x] Workflow 1: classify_message (already native)
- [x] Workflow 2: check_consent (already native)
- [x] Workflow 3: send_whatsapp (native example created)
- [ ] Workflow 4: send_sms_fallback (needs update)
- [x] Workflow 5: log_message (already native)
- [x] Workflow 6: reconcile_payment (already native)
- [ ] Workflow 7: send_payment_confirmation (needs update)

### Services
- [ ] Remove graph-api-trade-facilitator.js
- [ ] Remove erpnext-bridge.js
- [ ] Remove mpesa-api.js
- [ ] Remove message-logger.js
- [ ] Remove payment-reconciler.js
- [ ] Remove sms-provider.js
- [ ] Update trade-facilitator.js (remove API calls)

### Documentation
- [x] Create NATIVE_INTEGRATIONS.md
- [ ] Update ARCHITECTURE.md
- [ ] Update WAAS_ARCHITECTURE.md
- [ ] Update INTEGRATION_CAPABILITIES_MATRIX.md

---

## 🎯 Next Actions

1. **Update remaining workflows** (4, 7) to use native nodes
2. **Test all workflows** with native nodes
3. **Remove API wrapper services** after testing
4. **Update documentation** to reflect changes

---

**Last Updated**: 2026-01-09  
**Status**: Strategy defined, example created, ready for implementation  
**Next**: Update workflows 4, 7 and remove API wrapper services

