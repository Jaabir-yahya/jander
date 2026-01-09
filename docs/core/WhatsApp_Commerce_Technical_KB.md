# Nairobi WhatsApp Commerce Platform - Technical Knowledge Base

**Compiled**: January 9, 2026  
**Location**: Nairobi, Kenya  
**Purpose**: Comprehensive technical support documentation for integrations, APIs, and multi-tenant architecture

---

## Table of Contents

1. [WhatsApp Business API Integration](#whatsapp-business-api-integration)
2. [M-Pesa Daraja API Integration](#m-pesa-daraja-api-integration)
3. [KRA eTIMS Tax Compliance](#kra-etims-tax-compliance)
4. [Supabase Multi-Tenant Architecture](#supabase-multi-tenant-architecture)
5. [n8n Workflow Automation](#n8n-workflow-automation)
6. [ERPNext Integration](#erpnext-integration)
7. [Kenya-Specific Considerations](#kenya-specific-considerations)
8. [Troubleshooting & Error Handling](#troubleshooting--error-handling)

---

## WhatsApp Business API Integration

### Overview

Two primary approaches for WhatsApp integration in Kenya:

1. **SMSLeopard** (Kenya Meta Partner) - Recommended for local support
2. **Meta WhatsApp Cloud API** (Direct) - More features, global support
3. **n8n Native Node** - For workflow automation

---

### SMSLeopard WhatsApp API (Kenya Partner)

#### Endpoint: Send Template Message

```
POST https://whatsapp.smsleopard.com/v1/whatsapp/send
```

#### Authentication

```bash
Authorization: Basic $(echo -n 'api_key:api_secret' | base64)
Content-Type: application/json
```

#### Request Body Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `destination` | string | Yes | Recipient phone (254720000000 or +254720000000) |
| `template_id` | string | Yes | Template ID from KRA eTIMS or custom templates |
| `phone_number_id` | string | Yes | Your WhatsApp Number ID (46646XXXXXXX268) |
| `component_list` | object | Yes | Template variables |

#### Component List Structure

```json
{
  "components": [
    {
      "component_type": "BODY",
      "fields": [
        { "name": "1", "value": "Customer Name" },
        { "name": "2", "value": "Order Amount KES 2500" },
        { "name": "3", "value": "2025-01-15" }
      ]
    }
  ]
}
```

#### Response Format

```json
{
  "recipients": [
    {
      "id": "bae1d2dd-f27d-4d2b-96d9-e907e12b0ba2",
      "cost": 0.8,
      "number": "+254725089232",
      "status": "Success"
    }
  ]
}
```

#### Phone Number Format Rules

- **International format**: `+254720000000`
- **Without plus**: `254720000000`
- **Local format NOT supported**: `0720000000` (will fail)

#### Template Message Examples

**Authentication Code Template**
```
*{{1}}* is your verification code. Do not share.
```

**Order Confirmation Template**
```
Hi {{1}}, your order #{{2}} worth {{3}} confirmed for {{4}}.
```

**Payment Received Template**
```
Payment of KES {{1}} received. Reference: {{2}}. Thank you!
```

#### Kenya-Specific Pricing & Limits

- **Unverified WABA**: 250 conversations per day (24-hour window)
- **Verified WABA**: Unlimited conversations
- **Cost**: KES 0.80-2.50 per message (varies by template type)
- **Template Approval**: 24-48 hours (SMSLeopard fast-track)
- **24-hour Conversation Window**: Only free with template messages outside this window

#### Webhook Configuration

Set callback URL in SMSLeopard dashboard:
```
https://your-domain.com/api/whatsapp/webhook
```

**Webhook payload structure differs from Meta's format** - ensure parsing accounts for SMSLeopard format.

---

## M-Pesa Daraja API Integration

### Overview

**M-Pesa Daraja API** is Safaricom's payment gateway for Kenya. Three primary use cases:

1. **STK Push** (Lipa Na M-Pesa Online) - Prompt customer for PIN
2. **C2B** (Customer to Business) - Customer initiates payment
3. **B2C** (Business to Customer) - Seller payouts

---

### STK Push (Lipa Na M-Pesa Online)

#### Step 1: Generate Access Token

```
GET https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials
Authorization: Basic $(echo -n 'CONSUMER_KEY:CONSUMER_SECRET' | base64)
```

**Response**:
```json
{
  "access_token": "AbCdEfGhIjKlMnOpQrStUvWxYz",
  "expires_in": 3600
}
```

#### Step 2: Initiate STK Push Request

```
POST https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: application/json
```

**Request Body**:
```json
{
  "BusinessShortCode": "174379",
  "Password": "base64(shortcode+passkey+timestamp)",
  "Timestamp": "20240115123000",
  "TransactionType": "CustomerPayBillOnline",
  "Amount": "1",
  "PartyA": "254720000000",
  "PartyB": "174379",
  "PhoneNumber": "254720000000",
  "CallBackURL": "https://your-domain.com/api/mpesa/callback",
  "AccountReference": "ORD-2025-001",
  "TransactionDesc": "Order Payment"
}
```

**Password Generation (Node.js)**:
```javascript
const shortcode = "174379";
const passkey = "abc123def456ghi789jkl012mno345pqr678stu";
const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
const credentials = shortcode + passkey + timestamp;
const password = Buffer.from(credentials).toString('base64');
```

#### Step 3: Handle STK Push Response

**Immediate Acknowledgement** (not transaction completion):
```json
{
  "ResponseCode": "0",
  "ResponseDescription": "Success. Request accepted for processing",
  "MerchantRequestID": "16813-1590513-1",
  "CheckoutRequestID": "ws_CO_DMZ_123456789_20231011123456"
}
```

#### Step 4: Receive Callback (Transaction Result)

**Callback to your `CallBackURL`**:
```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "16813-1590513-1",
      "CheckoutRequestID": "ws_CO_DMZ_123456789_20231011123456",
      "ResultCode": 0,
      "ResultDesc": "The service request has been accepted successfully",
      "CallbackMetadata": {
        "Item": [
          { "Name": "Amount", "Value": 1 },
          { "Name": "MpesaReceiptNumber", "Value": "LHR519S5K1K" },
          { "Name": "TransactionDate", "Value": 20231011123456 },
          { "Name": "PhoneNumber", "Value": 254720000000 }
        ]
      }
    }
  }
}
```

#### STK Push Error Codes (ResultCode)

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Process payment entry |
| 1 | Insufficient funds | Notify customer |
| 2 | Transaction declined | Customer cancelled |
| 17 | Duplicate transaction | Check for existing payment |
| 20 | Invalid account | Verify phone number |
| 1032 | Request timed out | Retry after 30 seconds |

#### Callback Validation (Security)

**CRITICAL**: Validate signature to prevent spoofing

```javascript
const crypto = require('crypto');

function validateM2MCallback(callback, signatureHeader) {
  const payload = JSON.stringify(callback);
  const hmac = crypto
    .createHmac('sha256', process.env.MPESA_SECRET)
    .update(payload)
    .digest('base64');
  
  return hmac === signatureHeader;
}
```

---

### Daraja API Authentication

#### Generate OAuth2 Token

```bash
# Sandbox
curl -X GET "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials" \
  -H "Authorization: Basic $(echo -n 'CONSUMER_KEY:CONSUMER_SECRET' | base64)"

# Production
curl -X GET "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials" \
  -H "Authorization: Basic $(echo -n 'CONSUMER_KEY:CONSUMER_SECRET' | base64)"
```

#### Credentials Setup

1. **Create app on Daraja Portal**: https://developer.safaricom.co.ke
2. **Generate API Key/Secret** in app settings
3. **Register Shortcode/Till Number**
4. **Passkey Configuration:**
   - **Sandbox**: Use default passkey (not visible in dashboard):
     ```
     bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
     ```
   - **Production**: Get unique passkey via "Go Live" process:
     - Apply for "Go Live" on Daraja Portal
     - Complete OTP verification
     - Receive production passkey via email
5. **For Production**: Submit "Go Live" request with:
   - Test cases documentation
   - Callback URL verification
   - Use case details (STK Push, C2B, B2C)
   - Organization information

---

### Payment Reconciliation Pattern

**Flow**:
```
1. Initiate STK Push → CheckoutRequestID received
2. Store CheckoutRequestID in pending_transaction table
3. Customer enters PIN → M-Pesa processes
4. Callback received with MpesaReceiptNumber
5. Validate callback signature
6. Match CheckoutRequestID to pending_transaction
7. Update payment_entry with M-Pesa reference
8. Auto-submit Sales Invoice
9. Send WhatsApp confirmation
```

#### Idempotency Handling

**Duplicate transactions can occur** - implement idempotency:

```sql
CREATE UNIQUE INDEX idx_mpesa_reference ON payment_entries(mpesa_receipt_number);

-- On callback receipt:
INSERT INTO payment_entries (order_id, mpesa_receipt, amount, status)
VALUES ('ORD-2025-001', 'LHR519S5K1K', 1000, 'completed')
ON CONFLICT (mpesa_receipt_number) 
DO UPDATE SET status = 'completed';
```

---

## KRA eTIMS Tax Compliance

### Overview

**eTIMS** (Electronic Tax Invoice Management System) is mandatory for all traders in Kenya.

- **OSCU** (Online Sales Control Unit) - For system-to-system integration
- **VSCU** (Virtual Sales Control Unit) - For SaaS/cloud solutions
- **PIN requirement** - Taxpayer Identification Number

---

### OSCU Registration Process

#### Step 1: Prerequisites

- Valid KRA PIN
- Physical business address
- Director(s) PIN(s)
- Mobile number linked to KRA account

#### Step 2: Portal Registration

1. Visit: https://itax.kra.go.ke/eservices/
2. Sign up with KRA PIN
3. Navigate to **Service Request → eTIMS**
4. Select **OSCU** option
5. Complete director confirmation (OTP sent to director mobile)
6. Submit **eTIMS Commitment Form**: https://www.kra.go.ke/images/publications/eTIMS-confirmation-document.pdf

#### Step 3: KRA Approval

- **Timeline**: 2-5 business days
- **Notification**: SMS sent to registered number "Service Request was approved"

#### Step 4: OSCU Initialization

```
1. Access OSCU from KRA servers
2. Verify device with:
   - Taxpayer PIN
   - Branch Office ID
   - Equipment Serial Number
3. Receive Communication Key from KRA eTIMS API
4. Store keys securely:
   - Taxpayer PIN
   - Branch ID
   - Communication Key
```

---

### OSCU API Integration

#### API Initialization

**Endpoint**: KRA eTIMS API Server (managed by KRA)

**Configuration Required**:
```json
{
  "pin": "A000000001",
  "branch_code": "00",
  "serial_number": "KD123456789",
  "communication_key": "...",
  "api_endpoint": "https://etims.kra.go.ke/api"
}
```

#### Invoice Submission Payload

```json
{
  "invoiceNumber": "INV-2025-001",
  "invoiceDate": "2025-01-15T10:30:00Z",
  "seller": {
    "pin": "A000000001",
    "name": "Sample Shop Ltd",
    "branch": "00"
  },
  "buyer": {
    "pin": "A999999999",
    "name": "John Doe",
    "tin": null
  },
  "items": [
    {
      "itemCode": "ITEM001",
      "itemName": "T-Shirt",
      "quantity": 2,
      "unitPrice": 500.00,
      "discount": 0,
      "tax": 0,
      "amount": 1000.00
    }
  ],
  "totals": {
    "subtotal": 1000.00,
    "tax": 0.00,
    "total": 1000.00
  },
  "paymentMethod": "CASH|CARD|MPESA",
  "qrCode": null
}
```

#### Invoice Submission Flow

```
1. Build invoice JSON
2. Submit to OSCU API
3. OSCU validates:
   - Invoice format
   - Item codes exist
   - Calculations correct
   - Duplicate check
4. KRA generates QR code
5. Return: qrCode + serialNumber
6. Display QR code on receipt
7. Store KRA serialNumber
```

---

## Supabase Multi-Tenant Architecture

### Overview

**Row-Level Security (RLS)** provides database-level tenant isolation.

---

### JWT-Based Tenant Isolation

#### JWT Claims Structure

```json
{
  "sub": "user-uuid-123",
  "email": "seller@shop.com",
  "tenant_id": "tenant-uuid-456",
  "role": "seller",
  "aud": "authenticated",
  "iat": 1704067200,
  "exp": 1704153600
}
```

#### Store tenant_id in app_metadata

```javascript
// When user signs up
const { data, error } = await supabase.auth.admin.createUser({
  email: 'seller@shop.com',
  password: 'secure_password',
  app_metadata: {
    tenant_id: 'tenant-uuid-456',
    shop_name: 'John\'s Electronics'
  }
});
```

---

### RLS Policy Examples

#### Policy 1: Users can view orders from their tenant only

```sql
CREATE POLICY "Users see their tenant orders"
ON orders
FOR SELECT
TO authenticated
USING (
  tenant_id = ((auth.jwt()::jsonb ->> 'app_metadata')::jsonb ->> 'tenant_id')::UUID
);
```

#### Policy 2: Users can insert orders only to their tenant

```sql
CREATE POLICY "Users insert to their tenant"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (
  tenant_id = ((auth.jwt()::jsonb ->> 'app_metadata')::jsonb ->> 'tenant_id')::UUID
);
```

#### Policy 3: Users can update only their orders

```sql
CREATE POLICY "Users update own orders"
ON orders
FOR UPDATE
TO authenticated
USING (
  tenant_id = ((auth.jwt()::jsonb ->> 'app_metadata')::jsonb ->> 'tenant_id')::UUID
  AND user_id = auth.uid()
)
WITH CHECK (
  tenant_id = ((auth.jwt()::jsonb ->> 'app_metadata')::jsonb ->> 'tenant_id')::UUID
);
```

---

### Multi-Tenant Schema Design

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  phone VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  shop_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  name VARCHAR NOT NULL,
  price DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  customer_phone VARCHAR NOT NULL,
  customer_name VARCHAR,
  total_amount DECIMAL(12,2),
  status VARCHAR DEFAULT 'pending',
  mpesa_reference VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## n8n Workflow Automation

### HTTP Request Node Configuration

#### Authentication Methods

**Basic Auth** (M-Pesa Daraja):
```
Username: CONSUMER_KEY
Password: CONSUMER_SECRET
```

**Bearer Token** (Meta WhatsApp API):
```
Bearer: YOUR_ACCESS_TOKEN
```

#### cURL Import Feature

n8n can import cURL commands directly - copy, open HTTP Request node, click "Import cURL", paste.

---

### Example Workflow: Order to Payment to Confirmation

```
1. Webhook (Order submitted via WhatsApp)
   ├─→ Parse message content
   ├─→ Lookup product details
   ├─→ Supabase INSERT order
   ├─→ HTTP Request (M-Pesa STK Push)
   └─→ WhatsApp confirmation message

2. Webhook (M-Pesa Callback - runs separately)
   ├─→ Validate signature
   ├─→ Supabase UPDATE order
   ├─→ HTTP Request (Submit to eTIMS)
   ├─→ ERPNext integration
   └─→ WhatsApp payment confirmation
```

---

## ERPNext Integration

### Overview

ERPNext is the "system of record" for invoices, customers, inventory.

---

### REST API Authentication

#### Generate API Key/Secret

```
1. ERPNext Dashboard
2. User Management → Select user
3. API Access (in Settings tab)
4. Click "Generate Keys"
5. Copy: API Key + API Secret
```

#### Authentication in n8n

```
HTTP Request Node
├─ Method: GET/POST
├─ URL: https://erpnext.yourdomain.com/api/resource/:doctype
├─ Auth: Header
│   ├─ Name: Authorization
│   └─ Value: token api_key:api_secret
└─ Content-Type: application/json
```

#### Create Sales Invoice

```javascript
POST https://erpnext.yourdomain.com/api/resource/Sales%20Invoice

Headers:
{
  "Authorization": "token api_key:api_secret",
  "Content-Type": "application/json"
}

Body:
{
  "customer": "John Doe",
  "posting_date": "2025-01-15",
  "company": "Your Business Ltd",
  "currency": "KES",
  "items": [
    {
      "item_code": "ITEM001",
      "qty": 2,
      "rate": 500,
      "amount": 1000
    }
  ],
  "custom_mpesa_reference": "LHR519S5K1K"
}
```

---

## Kenya-Specific Considerations

### Phone Number Standardization

All phone numbers must be stored as:
- **Format**: `254XXXXXXXXX` (country code + 9 digits)
- **Examples**: 
  - `254720123456` (Safaricom)
  - `254733456789` (Airtel)

**Validation**:
```javascript
function validateKenyanPhone(phone) {
  const pattern = /^254[1-9]\d{8}$/;
  if (!phone.match(pattern)) {
    throw new Error('Invalid Kenyan phone format. Use 254XXXXXXXXX');
  }
  return true;
}

// Normalize various formats
function normalizePhone(phone) {
  if (phone.startsWith('+')) phone = phone.slice(1);
  if (phone.startsWith('0')) phone = '254' + phone.slice(1);
  return phone;
}
```

### Currency & Decimal Precision

- **Currency**: KES (Kenyan Shilling)
- **M-Pesa**: Whole shillings only

```javascript
function toWholeShillings(amount) {
  return Math.round(amount);
}
```

### Timezone

- **Timezone**: EAT (East Africa Time, UTC+3)
- **Store**: All times in UTC
- **Display**: Convert to local time for users

---

## Troubleshooting & Error Handling

### Common Issues

#### M-Pesa STK Push ResultCode 1

**Problem**: Insufficient funds or transaction declined

**Solution**:
```javascript
if (resultCode === 1) {
  await sendWhatsApp({
    to: customerPhone,
    template: 'payment_failed_insufficient_funds'
  });
}
```

#### WhatsApp Template Approval Delayed

**Causes**:
- Forbidden words in template
- Account compliance issues

**Solution**: Reword template, resubmit

#### eTIMS Item Not Found (Code 002)

**Causes**: Item not registered in KRA system

**Solution**: Register item before submission

```javascript
async function validateItemCode(itemCode) {
  const { data } = await oscu.api.getItems();
  const exists = data.items.find(i => i.code === itemCode);
  
  if (!exists) {
    await oscu.api.registerItem({
      item_code: itemCode,
      item_name: 'My Item'
    });
  }
}
```

---

## Production Checklist

Before going live:

- [ ] M-Pesa "Go Live" approved
- [ ] WhatsApp templates approved
- [ ] eTIMS OSCU/VSCU initialized
- [ ] Supabase RLS enabled on all tables
- [ ] n8n using production endpoints
- [ ] ERPNext API tested
- [ ] Webhooks using HTTPS
- [ ] Error handling implemented
- [ ] Phone numbers standardized
- [ ] 7-day sandbox testing complete

---

## API Endpoint Reference

| Service | Sandbox | Production |
|---------|---------|------------|
| M-Pesa Auth | sandbox.safaricom.co.ke/oauth | api.safaricom.co.ke/oauth |
| STK Push | sandbox.safaricom.co.ke/mpesa | api.safaricom.co.ke/mpesa |
| WhatsApp | smsleopard.com/v1 | smsleopard.com/v1 |
| eTIMS | N/A | etims.kra.go.ke/api |
| Supabase | {PROJECT}.supabase.co/rest | {PROJECT}.supabase.co/rest |
| ERPNext | Local | yourdomain.com/api |

---

**Document Version**: 1.0  
**Last Updated**: January 9, 2026  
**Location**: Nairobi, Kenya