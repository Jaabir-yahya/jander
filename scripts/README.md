# Integration Test Scripts

## test-integrations.js

Comprehensive integration test that verifies your `.env` configuration by making **real API calls** to all services.

### What It Tests

1. **Supabase** - Real database query to verify connection
2. **Meta WhatsApp** - Real API call to verify access token
3. **M-Pesa Daraja** - Real OAuth call to get access token
4. **n8n** - Connection check (if running)
5. **Webhook Configuration** - Validates tokens and secrets

### Usage

```bash
# From project root
node scripts/test-integrations.js

# Or if dependencies are in apps/whatsapp-business/
cd apps/whatsapp-business
node ../../scripts/test-integrations.js
```

### Prerequisites

Install dependencies first:

```bash
# Option 1: Install at root
npm install dotenv axios @supabase/supabase-js

# Option 2: Use existing dependencies from whatsapp-business
cd apps/whatsapp-business
npm install
```

### Output

The script will show:
- ✅ **Green** - Tests that passed
- ⚠️ **Yellow** - Warnings (non-critical)
- ❌ **Red** - Tests that failed

### Example Output

```
🧪 Integration Test Suite
Testing all integrations with real API calls...

============================================================
📋 Checking Environment Variables
============================================================
  ✅ SUPABASE_URL: Set
  ✅ WHATSAPP_ACCESS_TOKEN: Set
  ...

============================================================
📊 Testing Supabase Connection
============================================================
✅ Supabase connection successful
   Found 1 tenant config(s)

============================================================
💬 Testing Meta WhatsApp API
============================================================
✅ WhatsApp access token is valid
   Phone Number: +254700123456
   Verified Name: Your Business

============================================================
💰 Testing M-Pesa Daraja API
============================================================
✅ M-Pesa OAuth authentication successful
   Environment: Sandbox
   Response time: 234ms

============================================================
📊 Test Summary
============================================================
✅ Passed: 8
⚠️  Warnings: 1
❌ Failed: 0

✅ All critical integrations are working!
🚀 Your .env configuration is complete and working!
```

### Exit Codes

- `0` - All critical tests passed
- `1` - One or more critical tests failed

### Notes

- The script makes **real API calls** - this verifies your credentials actually work
- M-Pesa test uses OAuth endpoint (doesn't cost anything)
- WhatsApp test fetches phone number info (doesn't send messages)
- Supabase test makes a simple query (doesn't modify data)

