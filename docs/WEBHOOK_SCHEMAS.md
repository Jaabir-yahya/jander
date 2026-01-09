# Webhook Payload Schemas & API Contracts

**Defines exact payload structures for all webhooks and API integrations.**

This document serves as the contract between services. All integrations must match these schemas.

**Reference**: See [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md) for architecture context and [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md) for integration requirements.

---

## WhatsApp Webhook Payloads

### SMSLeopard Format (Inbound Message)

```json
{
  "message": {
    "id": "wamid.XXX",
    "from": "+254700456789",
    "type": "text",
    "timestamp": "1704787200",
    "text": {
      "body": "I want 2m red chiffon"
    }
  },
  "status": null
}
```

### Meta Format (Inbound Message)

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "+254700000000",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "messages": [
              {
                "from": "254700456789",
                "id": "wamid.XXX",
                "timestamp": "1704787200",
                "type": "text",
                "text": {
                  "body": "I want 2m red chiffon"
                }
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

### Delivery Receipt (SMSLeopard)

```json
{
  "status": {
    "id": "wamid.XXX",
    "status": "delivered",
    "timestamp": "1704787250",
    "recipient_id": "+254700456789"
  }
}
```

### Delivery Receipt (Meta)

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "statuses": [
              {
                "id": "wamid.XXX",
                "status": "delivered",
                "timestamp": "1704787250",
                "recipient_id": "254700456789"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

---

## M-Pesa Webhook Payloads

### STK Push Callback (Payment Confirmed)

```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "29115-34620561-1",
      "CheckoutRequestID": "ws_CO_191220231020363123",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          {
            "Name": "Amount",
            "Value": 1000
          },
          {
            "Name": "MpesaReceiptNumber",
            "Value": "QR3UQR4O"
          },
          {
            "Name": "Balance"
          },
          {
            "Name": "TransactionDate",
            "Value": 20231219102036
          },
          {
            "Name": "PhoneNumber",
            "Value": 254700456789
          }
        ]
      }
    }
  }
}
```

### STK Push Callback (Payment Failed)

```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "29115-34620561-1",
      "CheckoutRequestID": "ws_CO_191220231020363123",
      "ResultCode": 1032,
      "ResultDesc": "Request cancelled by user"
    }
  }
}
```

### B2C Payout Result (Success)

```json
{
  "Result": {
    "ResultType": 0,
    "ResultCode": 0,
    "ResultDesc": "The service request is processed successfully.",
    "OriginatorConversationID": "29115-34620561-1",
    "ConversationID": "AG_20231219_00001234567890",
    "TransactionID": "QR3UQR4O",
    "ResultParameters": {
      "ResultParameter": [
        {
          "Key": "TransactionReceipt",
          "Value": "QR3UQR4O"
        },
        {
          "Key": "TransactionAmount",
          "Value": 950
        },
        {
          "Key": "B2CWorkingAccountAvailableFunds",
          "Value": 10000
        },
        {
          "Key": "B2CUtilityAccountAvailableFunds",
          "Value": 5000
        },
        {
          "Key": "TransactionCompletedDateTime",
          "Value": "19.12.2023 10:20:36"
        },
        {
          "Key": "ReceiverPartyPublicName",
          "Value": "254712345678 - John Doe"
        },
        {
          "Key": "B2CChargesPaidAccountAvailableFunds",
          "Value": 0
        },
        {
          "Key": "B2CRecipientIsRegisteredCustomer",
          "Value": "Y"
        }
      ]
    },
    "ReferenceData": {
      "ReferenceItem": [
        {
          "Key": "QueueTimeoutURL",
          "Value": "https://your-domain.com/mpesa/b2c-timeout"
        }
      ]
    }
  }
}
```

---

## n8n Internal Format (Between Workflows)

### Classified Message (from classify_message workflow)

```json
{
  "message_type": "order",
  "user_type": "buyer",
  "priority": "high",
  "session_allowed": true,
  "fallback_allowed": true,
  "phone": "+254700456789",
  "text": "I want 2m red chiffon",
  "type": "text",
  "message_id": "wamid.XXX",
  "timestamp": 1704787200
}
```

### Message Send Request (to send_whatsapp workflow)

```json
{
  "phone": "+254700456789",
  "message": "Your order has been received!",
  "message_type": "order_update",
  "priority": "high",
  "session_allowed": true,
  "fallback_allowed": true,
  "template_name": null
}
```

### Message Send Result (from send_whatsapp workflow)

```json
{
  "success": true,
  "channel": "whatsapp",
  "message_id": "wamid.XXX",
  "status": "delivered",
  "cost_kes": 0.75,
  "delivered_at": "2026-01-09T10:30:00Z"
}
```

---

## ERPNext API Contracts

### Create Order (POST /api/resource/Sales%20Order)

**Request:**
```json
{
  "customer": "+254700456789",
  "customer_name": "Jane Doe",
  "delivery_date": "2026-01-10",
  "items": [
    {
      "item_code": "P001",
      "item_name": "Red Chiffon, 2m",
      "qty": 1,
      "rate": 500.00
    }
  ],
  "total": 500.00,
  "grand_total": 500.00
}
```

**Response:**
```json
{
  "data": {
    "name": "SO-00001",
    "owner": "administrator",
    "creation": "2026-01-09 10:00:00",
    "modified": "2026-01-09 10:00:00",
    "modified_by": "administrator",
    "docstatus": 0,
    "idx": 0,
    "customer": "+254700456789",
    "customer_name": "Jane Doe",
    "delivery_date": "2026-01-10",
    "grand_total": 500.00,
    "status": "Draft"
  }
}
```

### Update Order Status (PUT /api/resource/Sales%20Order/{name})

**Request:**
```json
{
  "status": "Confirmed",
  "payment_status": "Pending"
}
```

### Query Orders by Phone (GET /api/resource/Sales%20Order?filters=...)

**Request:**
```
GET /api/resource/Sales%20Order?filters=[["customer", "=", "+254700456789"], ["status", "=", "Pending"]]
```

**Response:**
```json
{
  "data": [
    {
      "name": "SO-00001",
      "customer": "+254700456789",
      "grand_total": 500.00,
      "status": "Pending",
      "payment_status": "Pending"
    }
  ]
}
```

### Create Payment Record (POST /api/resource/Payment)

**Request:**
```json
{
  "payment_type": "Receive",
  "party_type": "Customer",
  "party": "+254700456789",
  "paid_amount": 500.00,
  "received_amount": 500.00,
  "references": [
    {
      "reference_doctype": "Sales Order",
      "reference_name": "SO-00001",
      "allocated_amount": 500.00
    }
  ],
  "mode_of_payment": "M-Pesa",
  "mpesa_receipt_number": "QR3UQR4O"
}
```

---

## Supabase API Contracts

### Query Buyer by Phone (GET /rest/v1/buyers?phone=eq.{phone})

**Request:**
```
GET /rest/v1/buyers?phone=eq.+254700456789&select=buyer_id,phone,name,conversation_window_expires_at
Headers:
  apikey: {SUPABASE_ANON_KEY}
  Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
```

**Response:**
```json
[
  {
    "buyer_id": "B20260109001",
    "phone": "+254700456789",
    "name": "Jane Doe",
    "conversation_window_expires_at": "2026-01-10T10:00:00Z"
  }
]
```

### Create Trade (POST /rest/v1/trades)

**Request:**
```json
{
  "buyer_phone": "+254700456789",
  "seller_phone": "+254712345678",
  "product_id": "P001",
  "product_name": "Red Chiffon, 2m",
  "quantity": 1,
  "unit_price": 500.00,
  "total_amount": 500.00,
  "delivery_area": "CBD",
  "status": "pending"
}
```

### Log Message (POST /rest/v1/message_logs)

**Request:**
```json
{
  "phone": "+254700456789",
  "channel": "whatsapp",
  "message_type": "order_update",
  "status": "delivered",
  "message_id": "wamid.XXX",
  "content_preview": "Your order has been received!",
  "cost_kes": 0.75,
  "related_entity_type": "order",
  "related_entity_id": "SO-00001"
}
```

---

## Error Response Formats

### Standard Error Response

```json
{
  "success": false,
  "error": "Error message",
  "error_code": "ERROR_CODE",
  "details": {
    "field": "additional context"
  }
}
```

### n8n Workflow Error

```json
{
  "success": false,
  "error": "Workflow execution failed",
  "workflow_id": "classify_message",
  "node_id": "extract-message",
  "error_message": "Cannot read property 'message' of undefined",
  "requires_review": true
}
```

---

## Idempotency

**All webhooks must support idempotency:**

1. **WhatsApp Webhooks**: Use `message_id` as idempotency key
2. **M-Pesa Callbacks**: Use `CheckoutRequestID` or `ConversationID` as idempotency key
3. **n8n Workflows**: Check if message already processed before processing

**Idempotency Check Pattern:**
```javascript
// Check if message already processed
const existing = await db.query(
  'SELECT * FROM message_logs WHERE message_id = $1',
  [messageId]
);

if (existing.length > 0) {
  return { success: true, already_processed: true };
}

// Process message
// ...
```

---

## Testing Webhook Payloads

### Test WhatsApp Webhook

```bash
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

### Test M-Pesa STK Callback

```bash
curl -X POST http://localhost:5678/webhook/mpesa/stk-callback \
  -H "Content-Type: application/json" \
  -d '{
    "Body": {
      "stkCallback": {
        "MerchantRequestID": "test_001",
        "CheckoutRequestID": "test_checkout_001",
        "ResultCode": 0,
        "ResultDesc": "Success",
        "CallbackMetadata": {
          "Item": [
            {"Name": "Amount", "Value": 1000},
            {"Name": "MpesaReceiptNumber", "Value": "TEST123"},
            {"Name": "PhoneNumber", "Value": 254700456789}
          ]
        }
      }
    }
  }'
```

---

## References

- **WaaS Architecture**: [`WAAS_ARCHITECTURE.md`](./WAAS_ARCHITECTURE.md)
- **Integration Capabilities**: [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md)
- **Communication Rails**: See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) if exists

---

**Last Updated**: 2026-01-09  
**Status**: Webhook schemas defined, ready for integration testing

