# Trader Onboarding Template

## 5-Minute Video Script: "How to Place Orders via WhatsApp"

### Introduction (30 seconds)
"Hi! Welcome to the Nairobi Commerce WhatsApp ordering system. This quick guide will show you how traders can receive and process orders automatically through WhatsApp."

### Step 1: Receiving Orders (1 minute)
"Customers send orders to your WhatsApp Business number in simple text format. For example:
- '2m red chiffon, Jane, +254700456789'
- Or they can send voice notes
- Or they can send product photos

The system automatically captures all orders and creates a record."

### Step 2: Order Confirmation (1 minute)
"When an order is received, the system automatically:
1. Creates an order number
2. Sends confirmation to the customer via WhatsApp
3. Logs everything in your Google Sheet

You can view all orders in your shared Google Sheet dashboard."

### Step 3: Payment Processing (1.5 minutes)
"When customers pay via M-Pesa:
1. They send payment to your Till number
2. The system automatically matches the payment to the order
3. You get instant confirmation when payment is received
4. The customer gets a confirmation message automatically

No manual matching needed!"

### Step 4: What You Need to Do (1 minute)
"Your part is simple:
1. Check your Google Sheet daily for new orders
2. When order status shows 'Payment Confirmed', prepare the items
3. Mark as 'Ready' when items are packed
4. Coordinate delivery (manual for now)

That's it! The system handles the rest automatically."

### Closing (30 seconds)
"Questions? Contact support via WhatsApp or email. Let's get started!"

---

## SMSLeopard Template Approval Checklist

Before going live, submit these message templates to SMSLeopard dashboard:

### Template 1: Order Confirmation
```
Template Name: order_confirmation
Language: English

Body:
Hi {{1}}, your order #{{2}} is confirmed.
Items: {{3}} × {{4}}
Total: KSh {{5}}
Pay to: {{6}} ({{7}})
Asante!

Parameters:
1. Customer Name
2. Order ID
3. Product Name
4. Quantity
5. Total Amount
6. Till Number
7. Trader Name
```

### Template 2: Payment Received
```
Template Name: payment_received
Language: English

Body:
✅ Payment received! Your order {{1}} is confirmed and ready for dispatch.
Delivery: {{2}}
Track: {{3}}

Parameters:
1. Order ID
2. Dispatch Date/Time
3. Tracking Link
```

### Template 3: Dispatch Notification
```
Template Name: dispatch_notification
Language: English

Body:
🚚 Your order {{1}} is on the way!
Rider: {{2}}, {{3}}
ETA: {{4}}
Track live: {{5}}

Parameters:
1. Order ID
2. Rider Name
3. Rider Phone
4. Estimated Time
5. Tracking Link
```

---

## Support Response SOPs

### Common Issues

**Issue: Order not received**
- Response: "Let me check our system. Can you share the order details or payment receipt?"
- Action: Check Google Sheets ORDERS tab, search by customer phone or order ID

**Issue: Payment not matched**
- Response: "I see your payment. Let me match it manually. Please share the M-Pesa receipt number."
- Action: Manually update ORDERS sheet with payment_ref, change payment_status to "Confirmed"

**Issue: Voice note unclear**
- Response: "I couldn't understand your voice note. Can you please type the order details? Format: [quantity] [item], [your name], [your phone]"
- Action: Check DAILY_LOG for flagged voice notes, process manually

**Issue: System not responding**
- Response: "Thanks for your order! The system is processing it. You'll receive confirmation shortly."
- Action: Check n8n workflows, verify webhooks are active

---

## Onboarding Checklist

- [ ] Trader WhatsApp Business number registered
- [ ] SMSLeopard account activated
- [ ] Google Sheet shared with trader
- [ ] M-Pesa Till number configured
- [ ] Message templates approved by SMSLeopard
- [ ] Test order processed successfully
- [ ] Payment matching tested
- [ ] Support contact information shared
- [ ] Onboarding video sent
- [ ] First real order captured

---

## Training Materials

1. **Quick Start Guide** (1-page PDF)
   - How to place orders
   - How to check order status
   - Payment process
   - Support contacts

2. **Google Sheet Tutorial** (2-minute video)
   - Navigating the sheet
   - Understanding order statuses
   - Finding specific orders
   - Checking daily logs

3. **Troubleshooting Guide** (PDF)
   - Common issues and solutions
   - How to manually process orders
   - When to contact support



