# Multi-Tenant Implementation Guide

**How to use tenant_config for multi-SME support in Nairobi.**

This guide explains how the native integrations wiring supports multiple SMEs, each with their own WABA, ERPNext, M-Pesa, and tax configuration.

**Reference**: See [`NATIVE_INTEGRATIONS.md`](./architecture/NATIVE_INTEGRATIONS.md) for the complete wiring diagram.

---

## Architecture Overview

### One WABA Per SME Model

Each SME (tenant) has:
- **Own WABA** (WhatsApp Business Account) - Phone Number ID + Access Token
- **Own ERPNext** instance (or company within shared instance)
- **Own M-Pesa** shortcode + credentials
- **Own Tax System** (eTIMS/KRA) configuration
- **Own Payment Rails** (M-Pesa, PesaLink, Airtel Money) with priorities

### Data Model

**`tenant_config` table** stores all per-SME configuration:

```sql
CREATE TABLE tenant_config (
  tenant_id TEXT UNIQUE NOT NULL, -- e.g., "sme_001", "nairobi_boutique"
  waba_phone_number_id TEXT,
  waba_access_token TEXT,
  erp_base_url TEXT,
  erp_company_name TEXT,
  erp_api_key TEXT,
  erp_api_secret TEXT,
  mpesa_shortcode TEXT,
  mpesa_passkey TEXT,
  payment_rails JSONB, -- [{"rail_type": "mpesa", "enabled": true, "priority": 1}, ...]
  tax_system JSONB, -- {"system": "etims", "pin": "A000000000", "oscu_endpoint": "..."}
  ...
);
```

---

## Workflow Pattern: Tenant Lookup First

**Every workflow should start with tenant lookup:**

```
1. Extract tenant_id (from webhook query param, or determine from phone)
2. Lookup tenant_config from Supabase
3. Use tenant_config for all downstream API calls
```

### Example: WhatsApp Inbound Message

```json
{
  "workflow": "whatsapp_inbound",
  "steps": [
    {
      "node": "Extract tenant_id",
      "source": "webhook query param: ?tenant_id=sme_001"
    },
    {
      "node": "Lookup Tenant Config",
      "action": "HTTP Request → Supabase",
      "url": "/rest/v1/tenant_config?tenant_id=eq.sme_001"
    },
    {
      "node": "Send WhatsApp",
      "action": "HTTP Request → WhatsApp API",
      "url": "https://graph.facebook.com/v18.0/{{tenant_config.waba_phone_number_id}}/messages",
      "headers": {
        "Authorization": "Bearer {{tenant_config.waba_access_token}}"
      }
    }
  ]
}
```

---

## Tenant ID Sources

### 1. Webhook Query Parameter (Recommended)

**SMSLeopard webhook URL:**
```
https://your-n8n-instance.com/webhook/whatsapp?tenant_id=sme_001
```

**Extract in workflow:**
```javascript
const tenantId = $json.query?.tenant_id || $json.params?.tenant_id;
```

### 2. Phone Number Lookup (Fallback)

If tenant_id not provided, lookup from:
- **Seller phone** → Get seller → Get seller's tenant_id
- **Buyer phone** → Get buyer's recent trade → Get trade's tenant_id

**Note**: This requires `tenant_id` column in `sellers` and `trades` tables.

### 3. Default Tenant (Development Only)

For single-tenant deployments or testing:
```javascript
const tenantId = $json.tenant_id || 'sme_001'; // Default fallback
```

---

## Workflow Updates Required

### All Workflows Should:

1. **Extract tenant_id** (from webhook, query param, or phone lookup)
2. **Lookup tenant_config** (HTTP Request → Supabase)
3. **Use tenant_config** for all API calls:
   - WhatsApp: `tenant_config.waba_phone_number_id`, `tenant_config.waba_access_token`
   - ERPNext: `tenant_config.erp_base_url`, `tenant_config.erp_api_key`
   - M-Pesa: `tenant_config.mpesa_shortcode`, `tenant_config.mpesa_passkey`
   - Tax: `tenant_config.tax_system.oscu_endpoint`, `tenant_config.tax_system.pin`

### Updated Workflows

**Workflow 00: `lookup_tenant_config`** (Utility)
- Reusable workflow for tenant lookup
- Can be called from other workflows or used as first node

**Workflow 01: `classify_message_v2`**
- Extract tenant_id from webhook query param
- Lookup tenant_config
- Pass tenant_id to downstream workflows

**Workflow 03: `send_whatsapp_v2`**
- Accept tenant_id as input
- Lookup tenant_config
- Use tenant_config.waba_phone_number_id and waba_access_token

**Workflow 06: `reconcile_payment_v2`**
- Extract tenant_id from M-Pesa callback query param
- Lookup tenant_config
- Use tenant_config.mpesa_shortcode for payment matching

**Workflow 08: `submit_to_etims`**
- Accept tenant_id as input
- Lookup tenant_config
- Use tenant_config.tax_system for eTIMS submission

**Workflow 09: `multi_rail_payment`**
- Accept tenant_id as input
- Lookup tenant_config
- Use tenant_config.payment_rails for routing

---

## Payment Rails Configuration

**Format** (stored in `tenant_config.payment_rails`):

```json
[
  {
    "rail_type": "mpesa",
    "shortcode": "123456",
    "enabled": true,
    "priority": 1
  },
  {
    "rail_type": "pesalink",
    "account_number": "01234567890",
    "api_token": "xxx",
    "pesalink_api_endpoint": "https://api.pesalink.co.ke/v1/payments",
    "enabled": true,
    "priority": 2
  },
  {
    "rail_type": "airtel_money",
    "merchant_code": "AIRTEL001",
    "api_token": "yyy",
    "airtel_api_endpoint": "https://api.airtelmoney.co.ke/v1/payments",
    "enabled": false,
    "priority": 3
  }
]
```

**Workflow Logic:**
1. Get payment_rails from tenant_config
2. Filter enabled rails
3. Sort by priority
4. Select first (highest priority)
5. Route to appropriate payment workflow

---

## Tax System Configuration

**Format** (stored in `tenant_config.tax_system`):

```json
{
  "system": "etims",
  "pin": "A000000000",
  "oscu_endpoint": "https://api.kra.go.ke/etims/oscu",
  "api_key": "API_KEY_HERE",
  "api_secret": "API_SECRET_HERE"
}
```

**Workflow Logic:**
1. Get tax_system from tenant_config
2. Extract pin, oscu_endpoint, api_key, api_secret
3. Submit invoice to KRA OSCU endpoint
4. Store QR code and KRA invoice ID

---

## Database Schema Updates

### Add tenant_id to Existing Tables

**Migration 003** adds `tenant_id` to:
- `trades` table
- `orders` table (if exists)
- `payments` table (if exists)

**For new deployments**, add `tenant_id` from the start:
```sql
CREATE TABLE trades (
  trade_id TEXT PRIMARY KEY,
  tenant_id TEXT, -- Multi-tenant key
  buyer_phone TEXT,
  seller_phone TEXT,
  ...
);
```

### Row Level Security (RLS)

**Enable RLS for tenant isolation:**

```sql
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;

CREATE POLICY trades_tenant_isolation ON trades
  USING (tenant_id = current_setting('app.current_tenant_id', true));
```

**Note**: RLS policies are commented out in migration 003. Enable when multi-tenancy is needed.

---

## Testing Multi-Tenant

### Test Scenario 1: Two Tenants, Same Phone

**Setup:**
- Tenant A: `sme_001` (Nairobi Boutique)
- Tenant B: `sme_002` (Eastleigh Textiles)
- Same phone number: `+254700456789`

**Test:**
1. Send WhatsApp message with `?tenant_id=sme_001`
2. Verify tenant_config lookup returns `sme_001` config
3. Verify WhatsApp sent using `sme_001` WABA
4. Send WhatsApp message with `?tenant_id=sme_002`
5. Verify tenant_config lookup returns `sme_002` config
6. Verify WhatsApp sent using `sme_002` WABA

### Test Scenario 2: Payment Rails Priority

**Setup:**
- Tenant has M-Pesa (priority 1, enabled) and PesaLink (priority 2, enabled)

**Test:**
1. Initiate payment for order
2. Verify M-Pesa STK push sent (highest priority)
3. Disable M-Pesa in tenant_config
4. Initiate payment again
5. Verify PesaLink payment sent (fallback to priority 2)

### Test Scenario 3: eTIMS Submission

**Setup:**
- Tenant has eTIMS configured with PIN and OSCU endpoint

**Test:**
1. Create invoice for tenant
2. Trigger eTIMS submission workflow
3. Verify invoice submitted to KRA OSCU endpoint
4. Verify QR code stored in invoice record
5. Verify KRA invoice ID stored

---

## Migration Checklist

- [ ] Run migration 003: `003_add_tenant_config.sql`
- [ ] Create sample tenant configs in Supabase
- [ ] Update webhook URLs to include `?tenant_id=sme_001`
- [ ] Update all workflows to extract tenant_id
- [ ] Update all workflows to lookup tenant_config
- [ ] Update all workflows to use tenant_config for API calls
- [ ] Test multi-tenant isolation (two tenants, verify no cross-leakage)
- [ ] Enable RLS policies (if needed)
- [ ] Add tenant_id to existing data (if migrating)

---

## Next Steps

1. **Run migration** in Supabase SQL Editor
2. **Create tenant configs** for test SMEs
3. **Update webhook URLs** in SMSLeopard dashboard
4. **Import updated workflows** into n8n
5. **Test end-to-end** with multiple tenants

**See [`NATIVE_INTEGRATIONS.md`](./architecture/NATIVE_INTEGRATIONS.md) for complete wiring diagram.**

---

**Last Updated**: 2026-01-09  
**Status**: ✅ Multi-tenant support ready  
**Next**: Run migration and test with multiple tenants

