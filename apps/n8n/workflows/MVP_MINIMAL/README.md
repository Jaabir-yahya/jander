# MVP MINIMAL DEPLOYMENT

**Purpose:** 3-workflow bare minimum for 48-hour market validation

---

## WORKFLOWS INCLUDED

1. **13_instagram_comment_trigger.json** - Instagram → WhatsApp
2. **10_handle_order_with_confirmation.json** - WhatsApp → Order
3. **06_reconcile_payment_v2.json** - M-Pesa → Payment

---

## DATABASE MIGRATIONS NEEDED

Run these 4 migrations in order:

1. `001_create_trade_facilitator_schema.sql` (tenants table)
2. `003_add_tenant_config.sql` (tenant_config table)
3. `002_add_waas_core_tables.sql` (orders, payments tables)

---

## DEPLOYMENT STEPS

1. **Create test Supabase project**
2. **Run 4 migrations** (tenants, tenant_config, orders, payments)
3. **Import 3 workflows** to n8n
4. **Configure credentials:**
   - Supabase (test project)
   - Instagram (test account)
   - M-Pesa (sandbox)
5. **Set workflows to INACTIVE** until Customer 1 ready

---

## TESTING CHECKLIST

- [ ] Workflow 13: Manual execution (no errors)
- [ ] Workflow 10: Manual execution (no errors)
- [ ] Workflow 06: Manual execution (no errors)
- [ ] Database: Empty tables (orders, payments)

---

## DISABLED WORKFLOWS

All other workflows should be:
- Renamed to `.disabled` extension
- NOT imported to n8n
- Kept in repo for future use

---

**Reference:** `docs/MVP_TESTING_PLAYBOOK.md` for full 48-hour validation process

