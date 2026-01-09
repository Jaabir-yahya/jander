# Native Integrations Strategy

**Leverage built-in integrations instead of custom API bridges.**

n8n, ERPNext, and other tools have native support for each other. Use these instead of building custom code.

---

## 🎯 Core Principle

**Use Native Integrations First, Custom Code Only When Needed**

- ✅ n8n native nodes → WhatsApp, ERPNext, Supabase, HTTP
- ✅ ERPNext webhooks → Trigger n8n workflows
- ✅ ERPNext API → Native REST endpoints
- ✅ Supabase → Native REST API (n8n HTTP Request node)
- ⚠️ Custom services → Only for complex business logic

---

## 📦 Native Integration Matrix

### n8n Native Nodes Available

| Integration | Native Node | Status | Use Case |
|------------|-------------|--------|----------|
| **WhatsApp Business API** | `n8n-nodes-base.whatsapp` | ✅ Available | Send/receive WhatsApp messages |
| **ERPNext** | `n8n-nodes-base.erpnext` | ✅ Available | Create/update ERPNext records |
| **Supabase** | `n8n-nodes-base.supabase` | ✅ Available | Database operations |
| **HTTP Request** | `n8n-nodes-base.httpRequest` | ✅ Available | Generic API calls |
| **Webhook** | `n8n-nodes-base.webhook` | ✅ Available | Receive webhooks |
| **M-Pesa** | Custom HTTP node | ⚠️ Use HTTP Request | M-Pesa Daraja API |

**Note**: Some integrations may require community nodes. Check n8n community nodes.

---

## 🔄 Refactored Architecture

### Before (Custom Code)
```
WhatsApp → Custom Service → n8n → Custom Service → ERPNext
```

### After (Native Integrations)
```
WhatsApp → n8n WhatsApp Node → n8n ERPNext Node → ERPNext
         ↓
    n8n Supabase Node → Supabase
```

---

## 📋 Integration Strategy by Component

### 1. WhatsApp Integration

**Before**: Custom `graph-api-trade-facilitator.js` service  
**After**: n8n native WhatsApp node

**Benefits**:
- ✅ Built-in authentication handling
- ✅ Automatic retry logic
- ✅ Template message support
- ✅ Delivery receipt handling
- ✅ No custom code maintenance

**Implementation**:
```json
{
  "name": "Send WhatsApp",
  "type": "n8n-nodes-base.whatsapp",
  "parameters": {
    "operation": "sendMessage",
    "phoneNumberId": "={{$env.PHONE_NUMBER_ID}}",
    "to": "={{$json.phone}}",
    "message": "={{$json.message}}",
    "template": "={{$json.template_name}}"
  }
}
```

**Or use HTTP Request node with WhatsApp API**:
```json
{
  "name": "Send WhatsApp",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://graph.facebook.com/v18.0/{{$env.PHONE_NUMBER_ID}}/messages",
    "authentication": "oAuth2",
    "bodyParameters": {
      "to": "={{$json.phone}}",
      "type": "text",
      "text": {"body": "={{$json.message}}"}
    }
  }
}
```

---

### 2. ERPNext Integration

**Before**: Custom `erpnext-bridge.js` service  
**After**: n8n native ERPNext node

**Benefits**:
- ✅ Built-in authentication (API key/secret)
- ✅ Automatic field mapping
- ✅ Error handling
- ✅ Batch operations support
- ✅ No custom code maintenance

**Implementation**:
```json
{
  "name": "Create Sales Order",
  "type": "n8n-nodes-base.erpnext",
  "parameters": {
    "operation": "create",
    "resource": "Sales Order",
    "customer": "={{$json.customer_phone}}",
    "items": "={{$json.items}}",
    "deliveryDate": "={{$json.delivery_date}}"
  }
}
```

**Or use HTTP Request with ERPNext REST API**:
```json
{
  "name": "Create Sales Order",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "={{$env.ERPNEXT_BASE_URL}}/api/resource/Sales%20Order",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "sendBody": true,
    "bodyParameters": {
      "customer": "={{$json.customer_phone}}",
      "items": "={{$json.items}}"
    }
  }
}
```

---

### 3. Supabase Integration

**Before**: Custom Supabase client in services  
**After**: n8n native Supabase node OR HTTP Request with Supabase REST API

**Benefits**:
- ✅ Built-in authentication (API keys)
- ✅ Automatic query building
- ✅ Real-time subscriptions (if needed)
- ✅ No custom code maintenance

**Implementation**:
```json
{
  "name": "Query Buyers",
  "type": "n8n-nodes-base.supabase",
  "parameters": {
    "operation": "select",
    "table": "buyers",
    "filters": {
      "phone": "={{$json.phone}}"
    }
  }
}
```

**Or use HTTP Request with Supabase REST API** (already doing this):
```json
{
  "name": "Query Buyers",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "GET",
    "url": "={{$env.SUPABASE_URL}}/rest/v1/buyers?phone=eq.{{$json.phone}}",
    "headerParameters": {
      "apikey": "={{$env.SUPABASE_ANON_KEY}}",
      "Authorization": "=Bearer {{$env.SUPABASE_SERVICE_ROLE_KEY}}"
    }
  }
}
```

---

### 4. M-Pesa Integration

**Before**: Custom `mpesa-api.js` service  
**After**: n8n HTTP Request node (M-Pesa has REST API)

**Benefits**:
- ✅ Standard HTTP operations
- ✅ Built-in retry logic
- ✅ Error handling
- ✅ No custom code maintenance

**Implementation**:
```json
{
  "name": "STK Push",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "={{$env.DARAJA_BASE_URL}}/mpesa/stkpush/v1/processrequest",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "sendBody": true,
    "bodyParameters": {
      "BusinessShortCode": "={{$env.MPESA_SHORTCODE}}",
      "Password": "={{$json.password}}",
      "Timestamp": "={{$json.timestamp}}",
      "TransactionType": "CustomerPayBillOnline",
      "Amount": "={{$json.amount}}",
      "PartyA": "={{$json.phone}}",
      "PartyB": "={{$env.MPESA_SHORTCODE}}",
      "PhoneNumber": "={{$json.phone}}",
      "CallBackURL": "={{$env.WEBHOOK_URL}}/mpesa/stk-callback",
      "AccountReference": "={{$json.order_id}}",
      "TransactionDesc": "Order payment"
    }
  }
}
```

---

## 🔄 Refactored Workflow Structure

### Workflow 1: classify_message (Refactored)

**Before**: Custom code in Code node  
**After**: Use n8n native nodes where possible

**Structure**:
```
Webhook (WhatsApp)
  ↓
Extract Message Data (Set node)
  ↓
Classify Message Type (Code node - business logic)
  ↓
Query Supabase (HTTP Request node - native Supabase REST)
  ↓
Determine User Type (Code node - business logic)
  ↓
Return Classification
```

**Key Change**: Use HTTP Request node for Supabase instead of custom service.

---

### Workflow 3: send_whatsapp (Refactored)

**Before**: Custom `graph-api-trade-facilitator.js`  
**After**: n8n HTTP Request node with WhatsApp API

**Structure**:
```
Input
  ↓
Check Conversation Window (HTTP Request → Supabase)
  ↓
Determine Message Type (Code node)
  ↓
Send WhatsApp (HTTP Request → WhatsApp API)
  ↓
Wait for Delivery (Wait node)
  ↓
Check Delivery Status (HTTP Request → WhatsApp API)
  ↓
Log Message (HTTP Request → Supabase)
```

**Key Change**: Use HTTP Request node for WhatsApp API instead of custom service.

---

### Workflow 6: reconcile_payment (Refactored)

**Before**: Custom `payment-reconciler.js`  
**After**: n8n native nodes

**Structure**:
```
M-Pesa Webhook
  ↓
Extract Payment Data (Code node)
  ↓
Query Orders (HTTP Request → Supabase)
  ↓
Match Payment (Code node - business logic)
  ↓
Update Order (HTTP Request → Supabase)
  ↓
Create Payment Record (HTTP Request → Supabase)
```

**Key Change**: Use HTTP Request nodes for all database operations.

---

## 🎯 Services to Keep vs Remove

### Keep (Business Logic)
- ✅ `trade-facilitator.js` - Complex business logic
- ✅ `order-parser.js` - Complex parsing logic
- ✅ `conversation-tracker.js` - Business logic
- ✅ `escrow-manager.js` - Business logic

### Remove/Simplify (Use Native Nodes)
- ⚠️ `graph-api-trade-facilitator.js` → Use n8n HTTP Request node
- ⚠️ `erpnext-bridge.js` → Use n8n ERPNext node or HTTP Request
- ⚠️ `mpesa-api.js` → Use n8n HTTP Request node
- ⚠️ `message-logger.js` → Use n8n HTTP Request → Supabase
- ⚠️ `payment-reconciler.js` → Use n8n HTTP Request → Supabase
- ⚠️ `sms-provider.js` → Use n8n HTTP Request node

**Rule**: Keep services for complex business logic. Use native nodes for simple CRUD operations.

---

## 📋 Updated Workflow Files

### Use Native Nodes in Workflows

**Example: send_whatsapp workflow**

Instead of:
```json
{
  "name": "Send WhatsApp",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "jsCode": "const api = require('./services/graph-api-trade-facilitator.js'); ..."
  }
}
```

Use:
```json
{
  "name": "Send WhatsApp",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://graph.facebook.com/v18.0/{{$env.PHONE_NUMBER_ID}}/messages",
    "authentication": "oAuth2",
    "bodyParameters": {
      "to": "={{$json.phone}}",
      "type": "text",
      "text": {"body": "={{$json.message}}"}
    }
  }
}
```

---

## 🔧 Configuration Changes

### n8n Credentials Setup

**Instead of environment variables in code**, use n8n credentials:

1. **WhatsApp Credentials**:
   - Type: OAuth2 or API Key
   - Store: Access Token, Phone Number ID

2. **ERPNext Credentials**:
   - Type: HTTP Basic Auth
   - Store: API Key, API Secret

3. **Supabase Credentials**:
   - Type: API Key
   - Store: Project URL, Service Role Key

4. **M-Pesa Credentials**:
   - Type: HTTP Basic Auth
   - Store: Consumer Key, Consumer Secret

**Benefits**:
- ✅ Centralized credential management
- ✅ No code changes needed for credential updates
- ✅ Better security (credentials not in code)

---

## 📊 Migration Path

### Phase 1: Update Workflows (No Code Changes)
1. Replace custom service calls with native nodes in workflows
2. Test workflows with native nodes
3. Keep services as backup

### Phase 2: Simplify Services (Optional)
1. Remove services that are just API wrappers
2. Keep services with complex business logic
3. Update documentation

### Phase 3: Clean Up (Optional)
1. Remove unused service files
2. Update architecture docs
3. Simplify deployment

---

## ✅ Benefits Summary

**Before (Custom Code)**:
- ❌ More code to maintain
- ❌ Custom error handling
- ❌ Custom retry logic
- ❌ More testing needed
- ❌ Harder to debug

**After (Native Integrations)**:
- ✅ Less code to maintain
- ✅ Built-in error handling
- ✅ Built-in retry logic
- ✅ Less testing needed
- ✅ Easier to debug (n8n UI)
- ✅ Better credential management
- ✅ Visual workflow debugging

---

## 🎯 Action Items

1. **Update Workflows** (Priority 1):
   - Replace custom service calls with native nodes
   - Use HTTP Request nodes for APIs
   - Use n8n credentials instead of env vars

2. **Keep Business Logic Services** (Priority 2):
   - Keep `trade-facilitator.js` (complex logic)
   - Keep `order-parser.js` (complex parsing)
   - Keep `conversation-tracker.js` (business logic)
   - Keep `escrow-manager.js` (business logic)

3. **Remove API Wrapper Services** (Priority 3):
   - Remove `graph-api-trade-facilitator.js` (use HTTP Request)
   - Remove `erpnext-bridge.js` (use ERPNext node or HTTP Request)
   - Remove `mpesa-api.js` (use HTTP Request)
   - Remove `message-logger.js` (use HTTP Request → Supabase)
   - Remove `payment-reconciler.js` (use HTTP Request → Supabase)
   - Remove `sms-provider.js` (use HTTP Request)

---

## 📚 References

- **n8n Nodes**: https://docs.n8n.io/integrations/
- **ERPNext API**: https://frappeframework.com/docs/user/en/api
- **Supabase REST API**: https://supabase.com/docs/reference/javascript/introduction
- **WhatsApp Business API**: https://developers.facebook.com/docs/whatsapp

---

**Last Updated**: 2026-01-09  
**Status**: Strategy defined, ready for implementation  
**Next**: Update workflows to use native nodes

