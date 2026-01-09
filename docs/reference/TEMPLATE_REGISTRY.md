# WhatsApp Message Template Registry

**Template governance system for Stage 1 foundation. All WhatsApp message templates must be pre-approved and tracked.**

Based on research: Stage 1 maturity marker requires template registry with approval workflow. This document tracks all templates, their approval status, versions, and performance.

**Reference**: This document supports Stage 1 in [`BUILD_PLAN.md`](./BUILD_PLAN.md). See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for stage definitions.

---

## Template Governance Workflow

1. **Create Template**: Define template content with variables
2. **Submit for Approval**: Submit to SMSLeopard/Meta dashboard
3. **Track Approval Status**: Monitor approval progress
4. **Version Control**: Track template versions (v1, v2, v3...)
5. **Usage Tracking**: Log every template usage
6. **Performance Monitoring**: Track delivery, engagement, conversion

**Approval Time Target**: < 24 hours (Stage 1 gate)

---

## Stage 1: Foundation Templates (Week 1-2)

### Template 1: Order Confirmation

**Template Name**: `order_confirmation`  
**Category**: Orders  
**Status**: ⏳ Pending Approval  
**Version**: v1  
**Language**: English

**Content**:
```
Hi {{customer_name}}, your order #{{order_id}} is confirmed.

Items: {{product_name}} × {{quantity}}
Total: KSh {{total}}

Pay to Till: {{till_number}} ({{trader_name}})

Asante!
```

**Variables**:
- `{{customer_name}}` - Customer name
- `{{order_id}}` - Order ID (e.g., O20260109001)
- `{{product_name}}` - Product name (e.g., "red chiffon")
- `{{quantity}}` - Quantity (e.g., 2)
- `{{total}}` - Total amount in KSh (e.g., 1000)
- `{{till_number}}` - M-Pesa Till number (e.g., 123456)
- `{{trader_name}}` - Trader business name

**Usage**: Sent immediately after order is created in database

**Performance Metrics**:
- Delivery rate: ⏳ (target: 90%+)
- Engagement rate: ⏳ (target: track)
- Conversion rate: ⏳ (target: track)

---

### Template 2: Payment Request

**Template Name**: `payment_request`  
**Category**: Payments  
**Status**: ⏳ Pending Approval  
**Version**: v1  
**Language**: English

**Content**:
```
Pay KSh {{amount}} for order #{{order_id}}.

Till: {{till_number}} ({{trader_name}})

Click here to pay: {{stk_push_link}}

Payment deadline: {{deadline}}
```

**Variables**:
- `{{amount}}` - Amount to pay (e.g., 1000)
- `{{order_id}}` - Order ID
- `{{till_number}}` - M-Pesa Till number
- `{{trader_name}}` - Trader business name
- `{{stk_push_link}}` - STK push payment link (or Till number)
- `{{deadline}}` - Payment deadline (e.g., "24 hours")

**Usage**: Sent 1 hour after order if payment not received

**Performance Metrics**:
- Delivery rate: ⏳ (target: 90%+)
- Click rate: ⏳ (target: track)
- Payment completion rate: ⏳ (target: track)

---

### Template 3: Payment Confirmation

**Template Name**: `payment_confirmation`  
**Category**: Payments  
**Status**: ⏳ Pending Approval  
**Version**: v1  
**Language**: English

**Content**:
```
✅ Payment received!

Order #{{order_id}} is confirmed and ready for dispatch.

Payment: KSh {{amount}}
Receipt: {{mpesa_receipt}}

Dispatch: {{dispatch_timeline}}

Asante!
```

**Variables**:
- `{{order_id}}` - Order ID
- `{{amount}}` - Amount paid
- `{{mpesa_receipt}}` - M-Pesa receipt number
- `{{dispatch_timeline}}` - Expected dispatch time (e.g., "Today 4-6 PM")

**Usage**: Sent immediately after payment is matched to order

**Performance Metrics**:
- Delivery rate: ⏳ (target: 90%+)
- Engagement rate: ⏳ (target: track)

---

### Template 4: Order Status

**Template Name**: `order_status`  
**Category**: Orders  
**Status**: ⏳ Pending Approval  
**Version**: v1  
**Language**: English

**Content**:
```
Your order #{{order_id}} status: {{status}}

{{status_details}}

{{tracking_info}}

Reply HELP for support.
```

**Variables**:
- `{{order_id}}` - Order ID
- `{{status}}` - Current status (e.g., "Pending", "Ready", "Dispatched", "Delivered")
- `{{status_details}}` - Status-specific details
- `{{tracking_info}}` - Tracking information (if dispatched)

**Usage**: Sent when customer asks "Where is my order?" or when status changes

**Performance Metrics**:
- Delivery rate: ⏳ (target: 90%+)
- Containment rate: ⏳ (target: 60-80% bot resolution)

---

### Template 5: Support Acknowledgment

**Template Name**: `support_acknowledgment`  
**Category**: Support  
**Status**: ⏳ Pending Approval  
**Version**: v1  
**Language**: English

**Content**:
```
Thank you for contacting {{trader_name}}.

We've received your request and will respond within {{response_time}}.

Ticket #{{ticket_id}}

For urgent matters, call {{trader_phone}}.

Asante!
```

**Variables**:
- `{{trader_name}}` - Trader business name
- `{{response_time}}` - Expected response time (e.g., "24 hours")
- `{{ticket_id}}` - Support ticket ID
- `{{trader_phone}}` - Trader phone number

**Usage**: Sent immediately when support request is received

**Performance Metrics**:
- Delivery rate: ⏳ (target: 90%+)
- Time-to-agent: ⏳ (target: <5 minutes)

---

## Stage 2: Containment Templates (Week 3-4)

### Template 6: Order Tracking Response

**Template Name**: `order_tracking_response`  
**Category**: Orders  
**Status**: ⏳ Planned (Week 3)  
**Version**: v1  
**Language**: English

**Content**:
```
Order #{{order_id}} status: {{status}}

{{status_description}}

{{next_step}}

Reply HELP for more support.
```

**Usage**: Auto-response to "Where is my order?" queries

---

### Template 7: Payment Link Response

**Template Name**: `payment_link_response`  
**Category**: Payments  
**Status**: ⏳ Planned (Week 3)  
**Version**: v1  
**Language**: English

**Content**:
```
You have {{pending_count}} pending order(s).

Total: KSh {{total_amount}}

Pay now: {{stk_push_link}}

Till: {{till_number}}
```

**Usage**: Auto-response to "I want to pay" queries

---

## Stage 3: Integration Templates (Week 5-8)

### Template 8: Dispatch Notification

**Template Name**: `dispatch_notification`  
**Category**: Orders  
**Status**: ⏳ Planned (Week 6)  
**Version**: v1  
**Language**: English

**Content**:
```
🚚 Your order #{{order_id}} is on the way!

Rider: {{rider_name}}, {{rider_phone}}
Tracking: {{tracking_link}}

Expected delivery: {{delivery_time}}

We'll notify you when it arrives.
```

**Usage**: Sent when order is marked "Ready" and dispatched

---

### Template 9: Delivery Confirmation

**Template Name**: `delivery_confirmation`  
**Category**: Orders  
**Status**: ⏳ Planned (Week 6)  
**Version**: v1  
**Language**: English

**Content**:
```
✅ Order #{{order_id}} delivered!

We hope you're happy with your purchase.

Please rate your experience: {{review_link}}

Thank you for your order!
```

**Usage**: Sent when order is marked "Delivered"

---

### Template 10: Review Request

**Template Name**: `review_request`  
**Category**: Orders  
**Status**: ⏳ Planned (Week 6)  
**Version**: v1  
**Language**: English

**Content**:
```
How was your order #{{order_id}}?

Please share your feedback: {{review_link}}

Your feedback helps us improve!
```

**Usage**: Sent 24 hours after delivery

---

### Template 11: Payment Reminder 1

**Template Name**: `payment_reminder_1`  
**Category**: Payments  
**Status**: ⏳ Planned (Week 6)  
**Version**: v1  
**Language**: English

**Content**:
```
Complete your order #{{order_id}}!

Total: KSh {{amount}}

Pay now: {{stk_push_link}}

Thank you!
```

**Usage**: Sent 24 hours after order if payment not received

---

### Template 12: Payment Reminder 2

**Template Name**: `payment_reminder_2`  
**Category**: Payments  
**Status**: ⏳ Planned (Week 6)  
**Version**: v2  
**Language**: English

**Content**:
```
Reminder: Order #{{order_id}} payment pending.

Amount: KSh {{amount}}

Pay now: {{stk_push_link}}

Please complete payment to confirm your order.
```

**Usage**: Sent 48 hours after order if payment not received

---

### Template 13: Payment Reminder Final

**Template Name**: `payment_reminder_final`  
**Category**: Payments  
**Status**: ⏳ Planned (Week 6)  
**Version**: v1  
**Language**: English

**Content**:
```
Last chance: Order #{{order_id}} payment pending.

Amount: KSh {{amount}}

Pay now: {{stk_push_link}}

If you have questions, reply HELP.
```

**Usage**: Sent 72 hours after order if payment not received → Escalate to trader

---

### Template 14: Payment Failure

**Template Name**: `payment_failure`  
**Category**: Payments  
**Status**: ⏳ Planned (Week 7)  
**Version**: v1  
**Language**: English

**Content**:
```
Payment for order #{{order_id}} timed out.

Please try again: {{stk_push_link}}

Or pay to Till: {{till_number}}

Need help? Reply HELP.
```

**Usage**: Sent when STK push expires without payment

---

## Stage 4: Maturity Templates (Week 9-12)

### Support Templates (Week 9)

**Template 15: Support Escalation**
- Sent when support request escalated to trader
- Includes context summary

**Template 16: Support Resolution**
- Sent when support issue resolved
- Includes resolution details

**Template 17: Support Follow-up**
- Sent 24 hours after resolution
- Checks customer satisfaction

**Template 18: Support Satisfaction**
- Satisfaction survey request
- 1-5 star rating link

### Returns Templates (Week 9)

**Template 19: Return Initiated**
- Return request acknowledgment
- Return instructions

**Template 20: Return Refund**
- Refund processed confirmation
- Refund amount and method

---

## Template Performance Tracking

### Metrics Schema

| Template | Approval Status | Version | Usage Count | Delivery Rate | Engagement Rate | Conversion Rate |
|----------|----------------|---------|-------------|---------------|-----------------|-----------------|
| `order_confirmation` | ⏳ Pending | v1 | 0 | - | - | - |
| `payment_request` | ⏳ Pending | v1 | 0 | - | - | - |
| `payment_confirmation` | ⏳ Pending | v1 | 0 | - | - | - |
| `order_status` | ⏳ Pending | v1 | 0 | - | - | - |
| `support_acknowledgment` | ⏳ Pending | v1 | 0 | - | - | - |

**Targets** (Stage 1):
- Delivery Rate: 90%+
- Template Approval Time: < 24 hours
- Usage Tracking: All templates logged

**Targets** (Stage 4):
- Engagement Rate: Track & optimize
- Conversion Rate: Track & optimize
- A/B Testing: Compare template variations

---

## Template Approval Process

### Step 1: Create Template

1. Define template content with variables
2. Choose category (Orders, Payments, Support, Returns)
3. Select language (English, Swahili, or bilingual)
4. Test variables with sample data

### Step 2: Submit for Approval

1. Submit to SMSLeopard/Meta dashboard
2. Include template name, content, variables
3. Provide sample message for approval team

### Step 3: Track Approval

1. Monitor approval status in SMSLeopard dashboard
2. Track approval time (target: < 24 hours)
3. Update template registry with approval status

### Step 4: Version Control

1. Track template versions (v1, v2, v3...)
2. A/B test variations (Stage 4)
3. Archive old versions (keep for reference)

### Step 5: Usage Tracking

1. Log every template usage (message_id, template_name, timestamp)
2. Track performance metrics (delivery, engagement, conversion)
3. Update template registry weekly

---

## Swahili Templates (Optional - Week 2+)

### Template: Order Confirmation (Swahili)

**Template Name**: `order_confirmation_sw`  
**Category**: Orders  
**Status**: ⏳ Planned (Week 2)  
**Version**: v1  
**Language**: Swahili

**Content**:
```
Habari {{customer_name}}, order #{{order_id}} imethibitishwa.

Bidhaa: {{product_name}} × {{quantity}}
Jumla: KSh {{total}}

Maliza Till: {{till_number}} ({{trader_name}})

Asante!
```

**Usage**: Alternative to English template for Swahili-speaking customers

---

## Template Backlog (Stage 4: 10-15 per Domain)

### Orders Domain (Target: 5 templates)
1. ✅ `order_confirmation` (v1)
2. ✅ `order_status` (v1)
3. ✅ `dispatch_notification` (v1, Week 6)
4. ✅ `delivery_confirmation` (v1, Week 6)
5. ✅ `review_request` (v1, Week 6)

**Total**: 5 templates ✅

### Payments Domain (Target: 3 templates)
1. ✅ `payment_request` (v1)
2. ✅ `payment_confirmation` (v1)
3. ✅ `payment_reminder_1` (v1, Week 6)
4. ✅ `payment_reminder_2` (v1, Week 6)
5. ✅ `payment_reminder_final` (v1, Week 6)
6. ✅ `payment_failure` (v1, Week 7)

**Total**: 6 templates ✅ (exceeds target)

### Support Domain (Target: 5 templates)
1. ✅ `support_acknowledgment` (v1)
2. ⏳ `support_escalation` (v1, Week 9)
3. ⏳ `support_resolution` (v1, Week 9)
4. ⏳ `support_followup` (v1, Week 9)
5. ⏳ `support_satisfaction` (v1, Week 9)

**Total**: 5 templates ⏳

### Returns Domain (Target: 2 templates)
1. ⏳ `return_initiated` (v1, Week 9)
2. ⏳ `return_refund` (v1, Week 9)

**Total**: 2 templates ⏳

**Grand Total**: 18 templates (exceeds Stage 4 target of 15 minimum)

---

## References

- **Stage 1 Requirements**: See [`BUILD_PLAN.md`](./BUILD_PLAN.md) Stage 1
- **Template Governance**: See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) Stage 1 definition
- **Communication Rails**: See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) Rail 5 (Send Responses)

---

**Last Updated**: 2026-01-09  
**Status**: Stage 1 templates pending approval (5 templates)  
**Next Review**: End of Week 1 (approval status update)

