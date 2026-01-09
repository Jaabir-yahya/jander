# Tomorrow's Quick Start - One-Page Reference

**Date:** January 9, 2026  
**Time:** 4-6 hours  
**Goal:** Deploy MVP, validate all 6 non-negotiables

---

## 🚀 Priority Order (Follow in Sequence)

### 1. Get Credentials (2-3 hours)
- [ ] **Supabase** (15 min): Create project, run 3 migrations
- [ ] **SMSLeopard** (30-60 min): WhatsApp Business API account
- [ ] **SMS Provider** (15-30 min): AfricasTalking or SMSLeopard
- [ ] **M-Pesa Daraja** (30-60 min): Sandbox credentials
- [ ] **Environment Variables** (10 min): Create .env file

### 2. Test & Configure (1-2 hours)
- [ ] **Database**: Verify all 13 tables created
- [ ] **n8n**: Import 8 workflows, configure env vars
- [ ] **Webhooks**: Configure SMSLeopard + M-Pesa callbacks
- [ ] **Test**: Run sample data through workflows
- [ ] **Sample Tenant**: Create tenant_config row

### 3. Deploy (1 hour)
- [ ] **Templates**: Submit 5 core templates (manual, 24-48hr approval)
- [ ] **Webhooks**: Configure production URLs
- [ ] **Test E2E**: Send WhatsApp → Order → Payment → Confirm
- [ ] **Monitor**: Check logs for 24 hours

---

## 🔒 Non-Negotiables Validation (Before Week 1 Complete)

**See [ARCHITECTURE_PRINCIPLES.md](../core/ARCHITECTURE_PRINCIPLES.md) for full details.**

### Quick Validation Checklist:
1. ✅ **Three-Layer Separation**: Can I query orders/payments/customers in Supabase without WhatsApp?
2. ✅ **Phone Number Identity**: Can I find customer history using only phone number?
3. ✅ **Payment Reconciliation**: Can I auto-match 95%+ of M-Pesa payments?
4. ✅ **Consent Tracking**: Can I prove compliance for marketing messages?
5. ✅ **Human Escalation**: Does review queue exist for edge cases?
6. ✅ **Multi-Tenant Design**: Can I add 2nd trader without code changes?

**If all 6 validated ✅, you're ready to scale.**

---

## 📋 Critical Path Items

**Must Complete Today:**
- Supabase migrations (blocks everything else)
- SMSLeopard account (needed for WhatsApp webhooks)
- M-Pesa Daraja sandbox (needed for payment testing)
- Environment variables (needed for all workflows)

**Can Defer:**
- Template approval (use session messages in 24h window)
- SMS provider (can add later if WhatsApp works)
- First trader onboarding (can test with sample data first)

---

## 🚨 Common Pitfalls (Avoid These)

1. **Don't skip database migrations** - Multi-tenant breaks without tenant_id fields
2. **Don't hardcode tenant assumptions** - Use tenant_config table from day 1
3. **Don't skip consent tracking** - Meta will block you without it
4. **Don't store business truth in n8n** - All orders/payments go to Supabase
5. **Don't ignore payment reconciliation** - Manual matching doesn't scale

---

## 📚 Key References

**Before Starting:**
- [ARCHITECTURE_PRINCIPLES.md](../core/ARCHITECTURE_PRINCIPLES.md) - ⭐ **Non-negotiables vs flexible areas**
- [WEEK1_ACTION_PLAN.md](./WEEK1_ACTION_PLAN.md) - Complete step-by-step guide
- [WhatsApp_Commerce_Technical_KB.md](../core/WhatsApp_Commerce_Technical_KB.md) - Integration details

**During Setup:**
- Use WEEK1_ACTION_PLAN.md for detailed steps
- Use WhatsApp_Commerce_Technical_KB.md for API details
- Use ARCHITECTURE_PRINCIPLES.md for decision-making

---

## ✅ Success Criteria (Week 1 Complete When)

- [ ] All credentials obtained
- [ ] Database migrations successful
- [ ] Workflows imported and tested
- [ ] Webhooks receiving messages
- [ ] Payment matching 95%+ accuracy
- [ ] Message parsing 80%+ accuracy
- [ ] First trader onboarded
- [ ] Zero data isolation breaches
- [ ] **All 6 non-negotiables validated** ✅

---

**Last Updated:** January 9, 2026  
**Status:** Ready for Tomorrow  
**Full Guide:** See [WEEK1_ACTION_PLAN.md](./WEEK1_ACTION_PLAN.md) for complete details
