-- Seed Knowledge Base: 10 Critical Articles
-- Part of Nairobi Super Suite: Emergency Support Infrastructure
-- 
-- These are the 10 most common support questions
-- Date: January 9, 2026

-- Article 1: Instagram comment → WhatsApp not working?
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'Instagram comment → WhatsApp not working?',
  'instagram-comment-whatsapp-not-working',
  'Troubleshoot why Instagram comments are not triggering WhatsApp messages',
  '## Problem: Instagram comments not triggering WhatsApp

### Common Causes:
1. **Instagram Business Account not connected**
   - Go to Meta Business Suite → Instagram → Settings
   - Ensure your Instagram account is connected as a Business account
   - Verify webhook subscriptions are active

2. **Webhook not configured**
   - Check n8n workflow: `13_instagram_comment_trigger.json`
   - Verify webhook URL is active in Meta App Dashboard
   - Test webhook with Meta Webhook Test tool

3. **Comment format incorrect**
   - Customer must comment "YES" or similar trigger word
   - Check tenant_config.instagram_trigger_words setting
   - Ensure comment is on a Reel, not a regular post

### Quick Fix:
1. Go to Meta Business Suite → Webhooks
2. Click "Test" on Instagram Comments webhook
3. If test fails, re-subscribe to webhook events

### Still not working?
Contact support with:
- Your Instagram handle
- Screenshot of the comment
- Time when comment was made',
  ARRAY['instagram', 'whatsapp', 'webhook', 'troubleshooting'],
  'troubleshooting',
  NOW()
);

-- Article 2: M-Pesa payment not showing up?
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'M-Pesa payment not showing up?',
  'mpesa-payment-not-showing',
  'What to do when customer paid but payment is not reconciled',
  '## Problem: M-Pesa payment received but not showing in system

### Check These First:
1. **Payment reconciliation status**
   - Go to Payments tab in dashboard
   - Check "Pending Review" section
   - Payment may be queued for manual review

2. **Payment amount mismatch**
   - System uses ±15 KSh tolerance for fuzzy matching
   - If amount differs by more than 15 KSh, manual review required
   - Check customer phone number matches

3. **Payment timestamp**
   - Payments are matched within 24 hours of order creation
   - If order is older, check "Unmatched Payments" section

### Quick Fix:
1. Go to Payments → Unmatched
2. Find the payment by M-Pesa receipt number
3. Click "Match to Order" and select the correct order

### Manual Reconciliation:
If payment still not showing:
1. Get M-Pesa receipt number from customer
2. Get order ID from Orders tab
3. Contact support with both numbers

### Prevention:
- Always send order confirmation with exact amount
- Include order ID in M-Pesa payment description
- Use STK Push for automatic payment matching',
  ARRAY['mpesa', 'payment', 'reconciliation', 'troubleshooting'],
  'troubleshooting',
  NOW()
);

-- Article 3: How to update my catalog
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'How to update my catalog',
  'update-catalog',
  'Step-by-step guide to updating your product catalog',
  '## How to Update Your Product Catalog

### Method 1: Via WhatsApp (Recommended)
1. Send message: "Update catalog"
2. Follow the prompts to add/edit products
3. Use format: "Product name | Price | Description"

### Method 2: Via Dashboard
1. Log in to your dashboard
2. Go to Products → Catalog
3. Click "Add Product" or edit existing
4. Fill in:
   - Product name
   - Price (KSh)
   - Description
   - Stock quantity (if inventory enabled)

### Method 3: Bulk Upload (Coming Soon)
- Upload CSV file with products
- Format: name, price, description, stock

### Catalog Best Practices:
- Use clear product names
- Include sizes/colors in name
- Set realistic prices
- Update stock levels regularly
- Add product images (via WhatsApp)

### Need Help?
Send "catalog help" to support WhatsApp number.',
  ARRAY['catalog', 'products', 'setup', 'features'],
  'features',
  NOW()
);

-- Article 4: Business hours settings
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'Business hours settings',
  'business-hours-settings',
  'Configure when your business is open and how to handle after-hours messages',
  '## Business Hours Settings

### Set Your Business Hours:
1. Go to Settings → Business Hours
2. Select days of week you are open
3. Set opening and closing times
4. Save changes

### After-Hours Behavior:
- **Auto-Reply:** Send automatic message when closed
- **Queue Messages:** Messages received after hours are queued
- **Next Day:** You receive all queued messages at opening time

### Example Setup:
```
Monday-Friday: 8 AM - 6 PM
Saturday: 9 AM - 4 PM
Sunday: Closed
```

### Auto-Reply Message:
Customize the message customers receive after hours:
"Thanks for your message! We are currently closed. We will respond during business hours (Mon-Fri 8 AM - 6 PM)."

### Emergency Override:
- You can always respond manually, even after hours
- Emergency mode bypasses business hours
- Support escalations work 24/7',
  ARRAY['business-hours', 'settings', 'setup', 'features'],
  'features',
  NOW()
);

-- Article 5: Low stock alerts setup
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'Low stock alerts setup',
  'low-stock-alerts-setup',
  'Configure inventory tracking and low stock notifications',
  '## Low Stock Alerts Setup

### Enable Inventory Tracking:
1. Go to Settings → Inventory
2. Toggle "Enable Inventory Tracking"
3. Set minimum stock threshold (default: 5 units)

### Add Stock Levels:
1. Go to Products → Catalog
2. Click on a product
3. Enter current stock quantity
4. Set minimum threshold for that product

### How Alerts Work:
- System checks stock every 30 minutes
- If stock ≤ threshold, you receive WhatsApp alert
- Alert includes: Product name, current stock, days until stockout

### Alert Message Format:
```
⚠️ Stock Alert
🏀 Pair Size 9: 3 pairs left
📦 Est. stockout: 2 days
👉 Reorder now?
```

### Best Practices:
- Set realistic thresholds (don''t set too low)
- Update stock after each sale
- Use alerts to plan reordering
- Enable for bestseller products first

### Disable Alerts:
- Go to Settings → Inventory
- Toggle off "Low Stock Alerts"
- Or set threshold to 0',
  ARRAY['inventory', 'stock', 'alerts', 'setup', 'features'],
  'features',
  NOW()
);

-- Article 6: ROAS dashboard explained
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'ROAS dashboard explained',
  'roas-dashboard-explained',
  'Understanding your Return on Ad Spend (ROAS) metrics',
  '## ROAS Dashboard Explained

### What is ROAS?
Return on Ad Spend (ROAS) = Revenue from ads / Money spent on ads

Example: You spent KSh 500 on Instagram ads, got KSh 2,000 in orders
ROAS = 2,000 / 500 = 4.0 (400% return)

### Dashboard Metrics:

**ROAS per Reel:**
- Shows which Reels drive the most revenue
- Click on a Reel to see detailed breakdown
- Use this to identify your best-performing content

**ROAS per Campaign:**
- Tracks performance of ad campaigns
- Compare different campaigns
- Optimize budget allocation

**Conversion Rate:**
- Orders / Leads × 100
- Higher is better
- Industry average: 5-10%

**Revenue Trends:**
- Daily/weekly/monthly revenue
- Identify growth patterns
- Spot seasonal trends

### How to Improve ROAS:
1. **Focus on high-ROAS Reels**
   - Create similar content
   - Boost those Reels with ads

2. **Optimize low-ROAS campaigns**
   - Test different ad copy
   - Adjust targeting
   - Lower budget or pause

3. **Improve conversion rate**
   - Faster WhatsApp responses
   - Better product descriptions
   - Clear pricing

### When to Check:
- Daily: Quick health check
- Weekly: Identify trends
- Monthly: Strategic planning',
  ARRAY['roas', 'analytics', 'dashboard', 'features'],
  'features',
  NOW()
);

-- Article 7: WhatsApp template messages
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'WhatsApp template messages',
  'whatsapp-template-messages',
  'Understanding WhatsApp template messages and when they are used',
  '## WhatsApp Template Messages

### What are Template Messages?
Template messages are pre-approved messages you can send outside the 24-hour conversation window.

### When Templates Are Used:
- **After 24 hours:** If customer hasn''t messaged in 24 hours
- **First contact:** When reaching out to a new lead
- **Marketing:** Promotional messages

### Template Requirements:
- Must be approved by Meta
- Cannot be changed after approval
- Must include clear opt-out option

### Session Messages (Free):
- Within 24-hour window after customer messages
- No approval needed
- Can be personalized
- Use these whenever possible to save costs

### Cost Comparison:
- **Template message:** KSh 0.75 per message
- **Session message:** FREE (within 24h window)

### Best Practices:
1. **Respond quickly** to stay in session window
2. **Use templates sparingly** (only when necessary)
3. **Personalize templates** with customer name
4. **Include clear call-to-action**

### Common Templates:
- Order confirmation
- Payment reminder
- Delivery update
- Catalog delivery
- Welcome message

### Need Custom Template?
Contact support to create custom template for your business.',
  ARRAY['whatsapp', 'templates', 'messaging', 'features'],
  'features',
  NOW()
);

-- Article 8: M-Pesa till number setup
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'M-Pesa till number setup',
  'mpesa-till-number-setup',
  'How to configure your M-Pesa till number for payments',
  '## M-Pesa Till Number Setup

### Step 1: Get Your Till Number
1. Register for M-Pesa Business account
2. Apply for Till Number at Safaricom agent
3. Receive Till Number (format: 5 digits)

### Step 2: Configure in System
1. Go to Settings → Payments → M-Pesa
2. Enter your Till Number
3. Enter M-Pesa Consumer Key (from Daraja API)
4. Enter M-Pesa Consumer Secret
5. Enter M-Pesa Passkey
6. Save settings

### Step 3: Test Payment
1. Send test STK Push to your phone
2. Complete payment
3. Verify payment appears in dashboard

### Where to Get API Credentials:
1. Go to Safaricom Daraja Developer Portal
2. Create app (if not already created)
3. Get Consumer Key and Secret
4. Generate Passkey

### Common Issues:

**"Invalid Till Number"**
- Verify Till Number is correct (5 digits)
- Ensure Till Number is active with Safaricom

**"Payment not received"**
- Check webhook URL is configured
- Verify Consumer Key/Secret are correct
- Test webhook with Safaricom test tool

**"STK Push not appearing"**
- Check phone number format (+254...)
- Verify phone has M-Pesa active
- Ensure sufficient M-Pesa balance

### Security:
- Never share your Consumer Secret
- Keep API credentials secure
- Use environment variables (not hardcoded)

### Need Help?
Contact support with:
- Your Till Number
- Error message (if any)
- Screenshot of settings page',
  ARRAY['mpesa', 'till-number', 'setup', 'payment'],
  'setup',
  NOW()
);

-- Article 9: Instagram business account requirements
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'Instagram business account requirements',
  'instagram-business-account-requirements',
  'What you need to connect Instagram to Nairobi Super Suite',
  '## Instagram Business Account Requirements

### Required:
1. **Instagram Business Account**
   - Not a personal account
   - Convert to Business in Instagram Settings

2. **Facebook Business Page**
   - Must be linked to Instagram account
   - Page must be published (not draft)

3. **Meta Business Suite Access**
   - Access to Meta Business Suite
   - Admin or Editor role on Facebook Page

4. **Instagram Account Connected to Meta App**
   - Instagram account added to Meta App
   - Webhooks subscribed in App Dashboard

### Step-by-Step Setup:

**Step 1: Convert to Business Account**
1. Open Instagram app
2. Go to Settings → Account
3. Switch to Professional Account
4. Choose Business Account
5. Connect to Facebook Page

**Step 2: Connect to Meta App**
1. Go to Meta App Dashboard
2. Add Instagram product
3. Connect your Instagram account
4. Grant necessary permissions

**Step 3: Subscribe to Webhooks**
1. Go to Webhooks section
2. Subscribe to "comments" event
3. Subscribe to "mentions" event
4. Enter webhook URL (provided by system)

### Permissions Needed:
- `instagram_basic`
- `instagram_manage_comments`
- `pages_read_engagement`

### Common Issues:

**"Account not found"**
- Ensure account is Business (not Personal)
- Check account is connected to Facebook Page

**"Webhook not receiving events"**
- Verify webhook URL is correct
- Test webhook subscription
- Check Instagram account is connected to app

**"Comments not triggering"**
- Ensure webhook is subscribed to "comments"
- Test with a comment on your Reel
- Check webhook logs in n8n

### Verification:
After setup, test by:
1. Post a Reel
2. Comment "YES" on the Reel
3. Check if WhatsApp message is sent

### Need Help?
Contact support with:
- Your Instagram handle
- Screenshot of Meta App Dashboard
- Error message (if any)',
  ARRAY['instagram', 'business-account', 'setup', 'requirements'],
  'setup',
  NOW()
);

-- Article 10: Common error messages
INSERT INTO knowledge_base_articles (title, slug, summary, content, tags, category, created_at) VALUES
(
  'Common error messages',
  'common-error-messages',
  'Understanding and fixing common error messages',
  '## Common Error Messages

### "Payment reconciliation failed"
**Meaning:** M-Pesa payment could not be automatically matched to an order

**Fix:**
1. Go to Payments → Unmatched
2. Manually match payment to order
3. Check if amount matches (within ±15 KSh)
4. Verify phone number matches

### "WhatsApp message failed to send"
**Meaning:** Message could not be delivered via WhatsApp

**Common Causes:**
- Customer phone number invalid
- Customer blocked your number
- WhatsApp API rate limit exceeded
- Template message not approved

**Fix:**
1. Verify phone number format (+254...)
2. Check if customer has WhatsApp
3. Wait 1 minute and retry
4. Use SMS fallback if enabled

### "Instagram webhook signature invalid"
**Meaning:** Webhook request from Instagram was not verified

**Fix:**
1. Check META_APP_SECRET environment variable
2. Verify webhook URL in Meta App Dashboard
3. Re-subscribe to webhook events
4. Contact support if persists

### "Order creation failed"
**Meaning:** System could not create order from WhatsApp message

**Common Causes:**
- Product not found in catalog
- Invalid price format
- Missing required fields

**Fix:**
1. Check product exists in catalog
2. Verify price format (numbers only)
3. Ensure customer phone number is provided
4. Retry order creation

### "STK Push failed"
**Meaning:** M-Pesa STK Push payment prompt could not be sent

**Common Causes:**
- Invalid phone number
- M-Pesa credentials incorrect
- Insufficient M-Pesa balance
- Network issue

**Fix:**
1. Verify phone number (+254 format)
2. Check M-Pesa credentials in settings
3. Ensure customer has M-Pesa active
4. Retry after 1 minute

### "Tenant not found"
**Meaning:** System could not find your tenant configuration

**Fix:**
1. Verify tenant_id in request
2. Check tenant_config table
3. Ensure account is activated
4. Contact support to verify setup

### "Rate limit exceeded"
**Meaning:** Too many requests in short time

**Fix:**
1. Wait 1 minute before retrying
2. Reduce request frequency
3. Check if other processes are running
4. Contact support if urgent

### General Troubleshooting:
1. **Check logs:** Go to Logs tab in dashboard
2. **Retry:** Most errors are temporary, retry after 1 minute
3. **Contact support:** If error persists, contact with:
   - Error message (exact text)
   - Time when error occurred
   - What you were trying to do
   - Screenshot (if available)',
  ARRAY['errors', 'troubleshooting', 'common-issues'],
  'troubleshooting',
  NOW()
);

-- Update search vectors (refresh)
UPDATE knowledge_base_articles SET updated_at = NOW();

