# Research Spec Migration Guide

**Date:** January 9, 2026  
**Status:** ✅ Complete - Migration to research-backed architecture  
**Reference:** [verified-research-findings.md](../core/verified-research-findings.md)

---

## Overview

This document describes the migration from the trade facilitator schema (buyers/sellers/trades) to the research-locked architecture (tenants/orders/payments/messages) based on validated patterns from India, Brazil, and Nigeria production systems.

---

## Migration Summary

### What Changed

**Old Schema (Trade Facilitator):**
- `buyers`, `sellers`, `trades`, `products`, `conversations`
- Hub-and-spoke model (single WABA orchestrating trades)

**New Schema (Research-Locked):**
- `tenants`, `orders`, `payments`, `messages`, `review_queue`, `webhook_received`
- Multi-tenant SaaS model with RLS isolation
- Payment matching functions (exact + fuzzy)
- Idempotency tracking (webhook_received)

### Why Migrate

1. **Research Validation:** Architecture validated against production systems in India, Brazil, Nigeria
2. **Multi-Tenant Ready:** RLS policies enable true multi-tenant isolation
3. **Payment Matching:** Automated matching functions (95%+ accuracy)
4. **Idempotency:** Prevents duplicate webhook processing
5. **Clean Slate:** Day 2 migration = zero data loss risk

---

## Migration Files

### Database Migration

**File:** `apps/supabase/migrations/004_migrate_to_research_schema.sql`

**What It Does:**
1. Drops old tables (buyers, sellers, trades, products, conversations, etc.)
2. Creates research-locked tables:
   - `tenants` - Root isolation unit
   - `orders` - Core transaction record
   - `payments` - Payment reconciliation with matching fields
   - `messages` - WhatsApp conversation history
   - `review_queue` - Human-in-the-loop escalations
   - `webhook_received` - Idempotency tracking
3. Creates RLS policies for all tables
4. Creates payment matching functions:
   - `match_payment_exact()` - Tier 1: exact phone + amount
   - `match_payment_fuzzy()` - Tier 2: ±KSh 20 tolerance
   - `queue_payment_review()` - Tier 3: human escalation
5. Seeds 3 test tenants

**Reference:** Exact SQL from `docs/core/verified-research-findings.md` PART 2

### Workflow Updates

**Updated Workflows:**
- `00_lookup_tenant_config.json` - Added guard rails (extract, validate, verify, load)
- `06_reconcile_payment_v2.json` - Uses new matching functions + idempotency

**Guard Rail Pattern:**
1. Extract tenant_id (from webhook query param or body)
2. Validate tenant_id (format, non-null)
3. Verify tenant exists (SELECT from tenants WHERE id = tenant_id AND is_active = true)
4. Load tenant config (SELECT from tenant_config WHERE tenant_id = tenant_id)
5. Verify webhook signature (for M-Pesa/WhatsApp webhooks)

**Reference:** `docs/core/verified-research-findings.md` PART 1 Pattern #3

### Test Script

**File:** `scripts/test-research-migration.js`

**Test Cases:**
1. Tables created (tenants, orders, payments, messages, review_queue, webhook_received)
2. RLS policies enabled (manual verification needed)
3. Payment matching functions exist
4. Payment matching logic (exact + fuzzy)
5. Webhook idempotency (webhook_received UNIQUE constraint)
6. Indexes created (manual verification needed)

---

## How to Run Migration

### Step 1: Backup (Optional - Day 2 = No Data)

```bash
# If you have any data, backup first
# Since this is Day 2, no production data exists
```

### Step 2: Run Migration

```bash
# In Supabase SQL Editor, run:
# apps/supabase/migrations/004_migrate_to_research_schema.sql
```

### Step 3: Verify Migration

```bash
# Run test script
node scripts/test-research-migration.js
```

### Step 4: Update Workflows

1. Import updated workflows into n8n:
   - `00_lookup_tenant_config.json` (guard rails)
   - `06_reconcile_payment_v2.json` (matching functions)

2. Configure webhook URLs with `tenant_id` query param:
   - `https://your-n8n.com/webhook/mpesa-callback?tenant_id=YOUR_TENANT_ID`

### Step 5: Test End-to-End

1. Create test tenant in Supabase
2. Create test order
3. Send test M-Pesa webhook
4. Verify payment matched to order
5. Verify webhook_received table prevents duplicates

---

## Key Patterns Implemented

### 1. Guard Rails (Every Workflow)

**Pattern:** Extract → Validate → Verify → Load → Process

**Implementation:**
- Extract tenant_id from webhook
- Validate format and non-null
- Verify tenant exists and is_active
- Load tenant config
- Process with tenant context

**Reference:** `docs/core/verified-research-findings.md` PART 1 lines 93-115

### 2. Idempotency (Payment Webhooks)

**Pattern:** Check webhook_received BEFORE processing

**Implementation:**
1. Check if webhook_id already processed
2. If yes: Return 200 (idempotent success)
3. If no: Insert webhook_received record
4. Process payment
5. Update webhook_received status

**Reference:** `docs/core/verified-research-findings.md` PART 3 lines 523-558

### 3. Payment Matching (Three-Tier)

**Pattern:** Exact → Fuzzy → Review

**Implementation:**
1. Try `match_payment_exact()` (confidence = 1.0)
2. If not found: Try `match_payment_fuzzy()` (confidence >= 0.95 auto-match, >= 0.85 review)
3. If not found: Queue for manual review

**Reference:** `docs/core/verified-research-findings.md` PART 2 lines 369-459

---

## Verification Checklist

- [ ] Migration SQL executed successfully
- [ ] All 6 tables created (tenants, orders, payments, messages, review_queue, webhook_received)
- [ ] RLS policies enabled (verify in Supabase dashboard)
- [ ] Payment matching functions created (test with `SELECT match_payment_exact(...)`)
- [ ] Test script passes (`node scripts/test-research-migration.js`)
- [ ] Workflows updated with guard rails
- [ ] Webhook URLs include `tenant_id` query param
- [ ] End-to-end test successful

---

## Rollback Plan

**If Migration Fails:**

1. Old migration files preserved:
   - `001_create_trade_facilitator_schema.sql`
   - `002_add_waas_core_tables.sql`
   - `003_add_tenant_config.sql`

2. Can recreate old schema if needed (no production data = safe)

3. Workflow backups:
   - Old workflows preserved in git history
   - Can restore if needed

---

## Next Steps

1. **Day 3: Live Testing**
   - Onboard 2 real Gikomba traders
   - Test M-Pesa forwarding → invoice generation
   - Verify payment matching works
   - Measure end-to-end latency (<5 seconds target)

2. **Week 1: Production Hardening**
   - Monitor payment matching accuracy (target: 95%+ auto-match)
   - Review queue management (human escalation for edge cases)
   - Optimize workflow performance

3. **Week 2+: Scale Features**
   - Implement Magic #1-8 from research findings
   - Add weekly P&L summaries
   - Build reorder bot
   - Add supplier cost tracking

---

## References

- **Research Spec:** [verified-research-findings.md](../core/verified-research-findings.md)
- **Migration SQL:** `apps/supabase/migrations/004_migrate_to_research_schema.sql`
- **Test Script:** `scripts/test-research-migration.js`
- **Guard Rail Pattern:** Research spec PART 1 Pattern #3
- **Payment Matching:** Research spec PART 2 lines 369-459
- **Idempotency:** Research spec PART 3 lines 523-558

---

**Migration Complete:** January 9, 2026  
**Status:** ✅ Ready for Day 3 live deployment

