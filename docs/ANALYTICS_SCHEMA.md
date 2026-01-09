# Analytics Schema & KPI Definitions

**Metrics definitions, KPI tracking structure, and dashboard requirements for Stage 4 maturity.**

Based on research: Stage 4 maturity marker requires analytics instrumentation (message → action → outcome tracking, not just "sent"). This document defines the analytics schema and KPIs for each stage.

**Reference**: This document supports Stage 4 in [`BUILD_PLAN.md`](./BUILD_PLAN.md). See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) for stage definitions.

---

## Analytics Overview

### Research Insight

**From India/Brazil/Nigeria case studies**: Mature WhatsApp commerce implementations track message → action → outcome, not just "sent". Analytics drives optimization (Serri case: 2.3X engagement via send time optimization).

**Your Implementation**: Track all message events, actions, and outcomes across workflows. Build analytics dashboard for Stage 4.

---

## Analytics Event Schema

### Event Types

**Message Events**:
- `message_sent` - Message sent to WhatsApp API
- `message_delivered` - Delivery confirmation received
- `message_read` - Read receipt received (if available)
- `message_failed` - Message delivery failed

**Action Events**:
- `link_clicked` - Customer clicked link in message
- `button_tapped` - Customer tapped button (WhatsApp Flow/Interactive)
- `stk_push_initiated` - STK push payment link sent
- `stk_push_completed` - STK push payment completed
- `template_opened` - Customer opened template message (if tracked)

**Outcome Events**:
- `order_created` - Order created from message
- `payment_matched` - Payment matched to order
- `order_dispatched` - Order marked as dispatched
- `order_delivered` - Order marked as delivered
- `review_submitted` - Customer submitted review
- `support_ticket_created` - Support ticket created
- `return_initiated` - Return request initiated

**Workflow Events**:
- `workflow_triggered` - Workflow started
- `workflow_completed` - Workflow finished successfully
- `workflow_failed` - Workflow failed (error)
- `intent_detected` - Intent classification result
- `bot_response_sent` - Automated response sent
- `human_handoff` - Escalated to human reviewer

---

## Database Schema (Supabase)

### Analytics Table

```sql
CREATE TABLE analytics (
  event_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  event_type TEXT NOT NULL, -- 'message_sent', 'message_delivered', 'order_created', etc.
  template_name TEXT, -- WhatsApp template name (if applicable)
  workflow_name TEXT, -- n8n workflow name (if applicable)
  customer_phone TEXT, -- Customer phone number
  order_id TEXT, -- Order ID (if applicable)
  trader_id TEXT, -- Trader ID
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  revenue_kes DECIMAL, -- Revenue from this event (if applicable)
  metadata JSONB, -- Additional context (message_id, intent, confidence, etc.)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_analytics_event_type ON analytics(event_type);
CREATE INDEX idx_analytics_template_name ON analytics(template_name);
CREATE INDEX idx_analytics_trader_id ON analytics(trader_id);
CREATE INDEX idx_analytics_timestamp ON analytics(timestamp);
CREATE INDEX idx_analytics_customer_phone ON analytics(customer_phone);
```

### Analytics Aggregation Views

**Daily Summary View**:
```sql
CREATE VIEW analytics_daily_summary AS
SELECT
  DATE(timestamp) as date,
  trader_id,
  event_type,
  COUNT(*) as event_count,
  SUM(revenue_kes) as total_revenue,
  COUNT(DISTINCT customer_phone) as unique_customers,
  COUNT(DISTINCT order_id) as unique_orders
FROM analytics
GROUP BY DATE(timestamp), trader_id, event_type;
```

**Template Performance View**:
```sql
CREATE VIEW analytics_template_performance AS
SELECT
  template_name,
  COUNT(*) FILTER (WHERE event_type = 'message_sent') as sent_count,
  COUNT(*) FILTER (WHERE event_type = 'message_delivered') as delivered_count,
  COUNT(*) FILTER (WHERE event_type = 'link_clicked') as clicked_count,
  COUNT(*) FILTER (WHERE event_type = 'order_created') as orders_created,
  ROUND(
    COUNT(*) FILTER (WHERE event_type = 'message_delivered')::NUMERIC /
    NULLIF(COUNT(*) FILTER (WHERE event_type = 'message_sent'), 0) * 100,
    2
  ) as delivery_rate,
  ROUND(
    COUNT(*) FILTER (WHERE event_type = 'link_clicked')::NUMERIC /
    NULLIF(COUNT(*) FILTER (WHERE event_type = 'message_delivered'), 0) * 100,
    2
  ) as engagement_rate,
  ROUND(
    COUNT(*) FILTER (WHERE event_type = 'order_created')::NUMERIC /
    NULLIF(COUNT(*) FILTER (WHERE event_type = 'message_delivered'), 0) * 100,
    2
  ) as conversion_rate,
  SUM(revenue_kes) FILTER (WHERE event_type = 'order_created') as total_revenue
FROM analytics
WHERE template_name IS NOT NULL
GROUP BY template_name;
```

---

## KPIs by Stage

### Stage 1: Foundation KPIs

**Primary KPIs**:
- **Delivery Rate**: % messages delivered successfully
  - Formula: `(message_delivered / message_sent) * 100`
  - Target: 90%+ (research benchmark)
  - Measurement: WhatsApp API delivery status webhooks

- **Parse Accuracy**: % orders parsed correctly
  - Formula: `(orders_parsed_correctly / total_orders) * 100`
  - Target: 80%+ (current: 83.3%)
  - Measurement: Manual review of parse results

- **Payment Match Rate**: % payments auto-matched to orders
  - Formula: `(payments_auto_matched / total_payments) * 100`
  - Target: 95%+
  - Measurement: Payment webhook matching logic

**Secondary KPIs**:
- Template approval time (target: <24hrs)
- System uptime (target: 99%+)
- Order processing time (target: track)

**Dashboard**: Basic metrics dashboard (Google Sheets or simple web dashboard)

---

### Stage 2: Containment KPIs

**Primary KPIs**:
- **Containment Rate**: % queries resolved by bot
  - Formula: `(bot_resolved_queries / total_queries) * 100`
  - Target: 60-80% (research benchmark)
  - Measurement: Intent detection + bot response tracking

- **Time-to-Agent**: Time from escalation to human response
  - Formula: `AVG(human_response_timestamp - escalation_timestamp)`
  - Target: < 5 minutes
  - Measurement: Review queue response time

- **Re-contact Rate**: % customers asking same question twice
  - Formula: `(customers_asking_twice / total_customers) * 100`
  - Target: < 20%
  - Measurement: Customer message history analysis

**Secondary KPIs**:
- Intent accuracy (target: 85%+)
- Bot response time (target: <2 seconds)
- Escalation rate by intent type

**Dashboard**: Containment metrics dashboard (bot vs human breakdown)

---

### Stage 3: Integration KPIs

**Primary KPIs**:
- **Cycle Time Reduction**: Time saved vs manual process
  - Formula: `(manual_time - automated_time) / manual_time * 100`
  - Target: 50%+ reduction
  - Measurement: Order creation → delivery time comparison

- **Payment Automation**: % payments fully automated
  - Formula: `(payments_auto_matched / total_payments) * 100`
  - Target: 95%+
  - Measurement: Payment webhook automation

- **Cart Recovery Rate**: % abandoned orders recovered
  - Formula: `(orders_recovered_after_reminder / abandoned_orders) * 100`
  - Target: 30-36% (research benchmark)
  - Measurement: Cart recovery sequence tracking

**Secondary KPIs**:
- Post-purchase sequence completion rate
- Payment retry success rate
- Return processing time

**Dashboard**: Integration metrics dashboard (end-to-end workflow tracking)

---

### Stage 4: Maturity KPIs

**Primary KPIs**:
- **ROI Ratio**: Revenue/Cost ratio
  - Formula: `(Revenue + Time_Savings_Value - Costs) / Costs`
  - Target: 18:1+ (research benchmark)
  - Measurement: Financial ROI calculation

- **Engagement Rate**: % messages that generate clicks/opens
  - Formula: `(link_clicked + button_tapped) / message_delivered * 100`
  - Target: Track & optimize (India: 45%+, Brazil: 40%+)
  - Measurement: Analytics event tracking

- **Conversion Rate**: % messages that generate orders
  - Formula: `(orders_created_from_message / message_delivered) * 100`
  - Target: Track & optimize
  - Measurement: Message → Order attribution

**Secondary KPIs**:
- Cost per contact (target: minimize)
- CSAT movement (target: positive trend)
- Template performance (A/B testing results)
- Send time optimization (Kenya-specific optimal times)

**Dashboard**: Comprehensive analytics dashboard (all KPIs, trends, insights)

---

### Stage 5: Predictive KPIs

**Primary KPIs**:
- **Revenue per Contact**: Revenue generated per message sent
  - Formula: `total_revenue / total_messages_sent`
  - Target: Track & optimize
  - Measurement: Revenue attribution to WhatsApp

- **Churn Reduction**: % inactive customers recovered
  - Formula: `(customers_reactivated / inactive_customers) * 100`
  - Target: Track & optimize
  - Measurement: Retention campaign tracking

- **AI Intent Accuracy**: % intents classified correctly by AI
  - Formula: `(correct_intent_classifications / total_classifications) * 100`
  - Target: 95%+ (research benchmark)
  - Measurement: AI model evaluation

**Secondary KPIs**:
- Proactive notification effectiveness
- Retention campaign ROI
- Predictive model accuracy

**Dashboard**: Predictive analytics dashboard (churn prediction, revenue forecasting)

---

## Metrics Dashboard Requirements

### Stage 1 Dashboard (Week 2)

**Basic Metrics**:
- Orders processed (count)
- Parse accuracy (%)
- Payment match rate (%)
- Delivery rate (%)
- Time saved (hours/day)
- Template usage (per template)

**Location**: Google Sheets (simple) or basic web dashboard

**Update Frequency**: Daily

---

### Stage 2 Dashboard (Week 4)

**Containment Metrics**:
- Containment rate (bot vs human)
- Time-to-agent (average, median)
- Re-contact rate
- Intent accuracy per intent type
- Bot response time

**Location**: Google Sheets or Supabase dashboard

**Update Frequency**: Daily

---

### Stage 3 Dashboard (Week 8)

**Integration Metrics**:
- Cycle time (order → delivery)
- Payment automation rate
- Cart recovery rate
- Post-purchase sequence completion
- Payment retry success rate

**Location**: Supabase dashboard (real-time)

**Update Frequency**: Real-time

---

### Stage 4 Dashboard (Week 12)

**Comprehensive Metrics**:
- ROI ratio (revenue/cost)
- Engagement rate (clicks/opens)
- Conversion rate (message → order)
- Cost per contact
- CSAT scores
- Template performance (A/B tests)
- Send time optimization results

**Location**: Supabase dashboard with analytics views

**Update Frequency**: Real-time

**Features**:
- Trend analysis (7-day, 30-day, 90-day)
- Cohort analysis (per trader, per week)
- Segment analysis (customer tier, intent type)
- Export to CSV/Excel

---

## KPI Calculation Examples

### Delivery Rate

```sql
-- Daily delivery rate
SELECT
  DATE(timestamp) as date,
  COUNT(*) FILTER (WHERE event_type = 'message_delivered')::NUMERIC /
  NULLIF(COUNT(*) FILTER (WHERE event_type = 'message_sent'), 0) * 100 as delivery_rate
FROM analytics
WHERE event_type IN ('message_sent', 'message_delivered')
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### Containment Rate

```sql
-- Weekly containment rate
SELECT
  DATE_TRUNC('week', timestamp) as week,
  COUNT(*) FILTER (WHERE event_type = 'bot_response_sent')::NUMERIC /
  NULLIF(COUNT(*) FILTER (WHERE event_type = 'intent_detected'), 0) * 100 as containment_rate
FROM analytics
WHERE event_type IN ('intent_detected', 'bot_response_sent', 'human_handoff')
GROUP BY DATE_TRUNC('week', timestamp)
ORDER BY week DESC;
```

### ROI Calculation

```sql
-- Monthly ROI calculation
SELECT
  DATE_TRUNC('month', timestamp) as month,
  SUM(revenue_kes) as total_revenue,
  -- Cost calculation (from separate costs table)
  SUM(cost_kes) as total_cost,
  -- ROI = (Revenue - Cost) / Cost * 100
  ROUND(
    (SUM(revenue_kes) - SUM(cost_kes)) / NULLIF(SUM(cost_kes), 0) * 100,
    2
  ) as roi_percentage,
  -- ROI ratio = Revenue / Cost
  ROUND(
    SUM(revenue_kes) / NULLIF(SUM(cost_kes), 0),
    2
  ) as roi_ratio
FROM analytics
LEFT JOIN costs ON DATE_TRUNC('month', analytics.timestamp) = DATE_TRUNC('month', costs.date)
WHERE event_type = 'order_created'
GROUP BY DATE_TRUNC('month', timestamp)
ORDER BY month DESC;
```

---

## Analytics Instrumentation Points

### n8n Workflow Instrumentation

**Message Sent**:
- Log `message_sent` event when sending WhatsApp message
- Include: template_name, customer_phone, order_id, timestamp

**Message Delivered**:
- Log `message_delivered` event when delivery webhook received
- Include: message_id, delivery_timestamp, delivery_status

**Link Clicked**:
- Log `link_clicked` event when customer clicks link
- Include: link_url, customer_phone, template_name

**Order Created**:
- Log `order_created` event when order created
- Include: order_id, customer_phone, revenue_kes, source (whatsapp)

**Payment Matched**:
- Log `payment_matched` event when payment matched
- Include: order_id, payment_id, amount_kes, match_confidence

### Database Triggers (Supabase)

**Automated Logging**:
- Trigger on `orders` table INSERT → Log `order_created`
- Trigger on `payments` table UPDATE → Log `payment_matched`
- Trigger on `orders` table UPDATE (status change) → Log workflow event

---

## References

- **Stage 4 Requirements**: See [`BUILD_PLAN.md`](./BUILD_PLAN.md) Stage 4
- **Analytics Research**: See [`LIFECYCLE_STAGES.md`](./LIFECYCLE_STAGES.md) Stage 4 definition
- **Communication Rails**: See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) for data flow tracking

---

**Last Updated**: 2026-01-09  
**Status**: Stage 1 metrics tracking (basic)  
**Next Review**: Week 2 (add Stage 2 metrics), Week 9 (build Stage 4 dashboard)

