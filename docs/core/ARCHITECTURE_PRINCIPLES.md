# Architecture Principles: Non-Negotiables vs. Flexible Adaptations

**Based on proven patterns from India, Brazil, Nigeria, and Kenya**

This document defines what must be preserved (non-negotiables) versus what can adapt based on cost, rollout speed, and validation results (flexible areas). Use this as a decision-making framework when evaluating implementation choices.

**Status**: Core architectural guardrails - do not compromise these principles.  
**Last Updated**: 2026-01-09  
**Reference**: See [`WAAS_ARCHITECTURE.md`](../architecture/WAAS_ARCHITECTURE.md) for detailed architecture design.

---

## 🚨 Non-Negotiables (Architectural Guardrails)

**These are structural principles that, if compromised, create failure points or require heavy refactoring later. These are not feature choices - they are architectural guardrails.**

### 1. Three-Layer Separation

**Principle**: Channels (WhatsApp) → Orchestration → System of Record

**Why Non-Negotiable**:
- Conversations are transient; business data must persist independently
- Proven pattern across India, Brazil, Nigeria, Kenya
- Separates concerns: channels change, orchestration adapts, records persist
- Avoids tight coupling that causes failures at scale

**What This Means**:
- ✅ **Must have**: Clear separation between messaging (WhatsApp) and data storage (database)
- ✅ **Must have**: Orchestration layer that routes messages but doesn't store business truth
- ❌ **Cannot do**: Store orders/customers/payments in WhatsApp or orchestration workflows
- ❌ **Cannot do**: Mix channel-specific logic with business logic

**Validation Question**: "If WhatsApp shuts down tomorrow, can I still access all my orders, payments, and customers?"

**If No**: Architecture is broken - fix before scaling.

---

### 2. Phone Number as Primary Identity

**Principle**: Phone number = canonical customer identity (not email, not username)

**Why Non-Negotiable**:
- WhatsApp, SMS, USSD, M-Pesa all align on phone number
- Critical for payment reconciliation (M-Pesa uses phone number)
- Avoids identity fragmentation across channels
- Enables future KYC without major refactoring

**What This Means**:
- ✅ **Must have**: Phone number as UNIQUE, INDEXED, IMMUTABLE field
- ✅ **Must have**: All customer lookups by phone number first
- ✅ **Must have**: Phone number in all orders, payments, consent records
- ❌ **Cannot do**: Use email as primary key (users don't have reliable emails)
- ❌ **Cannot do**: Generate arbitrary user IDs (breaks M-Pesa matching)

**Validation Question**: "Can I find a customer's complete history (orders, payments, messages) using only their phone number?"

**If No**: Identity model is broken - fix before scaling.

---

### 3. Automated Payment Reconciliation

**Principle**: Automatic matching of M-Pesa payments to orders (95%+ match rate)

**Why Non-Negotiable**:
- Manual reconciliation does not scale (this is where chat-commerce startups die)
- Required for trust (traders must see payments matched to orders)
- Without this, traders revert to manual processes

**What This Means**:
- ✅ **Must have**: M-Pesa webhook callbacks (Daraja API)
- ✅ **Must have**: Idempotent payment matching logic (phone + amount ± tolerance)
- ✅ **Must have**: Manual review queue for unmatched payments (5% edge cases)
- ✅ **Must have**: Duplicate transaction handling (M-Pesa can send duplicates)
- ❌ **Cannot do**: Rely on screenshots or manual matching for production
- ❌ **Cannot do**: Ignore duplicate transactions

**Validation Question**: "Can I match 95%+ of M-Pesa payments to orders automatically without manual intervention?"

**If No**: Payment reconciliation is broken - fix before scaling.

---

### 4. Explicit Consent Tracking

**Principle**: Explicit consent records for WhatsApp (transactional vs marketing)

**Why Non-Negotiable**:
- Meta requirement (account blocks for non-compliance)
- Regulatory risk (Kenya consumer protection laws)
- Without consent records, platform can be shut down

**What This Means**:
- ✅ **Must have**: Consent records (phone, channel, purpose, timestamp, source)
- ✅ **Must have**: Transactional vs marketing distinction (transactional = implied, marketing = explicit)
- ✅ **Must have**: Opt-out mechanism
- ✅ **Must have**: Consent validation before sending marketing messages
- ❌ **Cannot do**: Send marketing messages without explicit consent
- ❌ **Cannot do**: Skip consent tracking "for now" (Meta will block you)

**Validation Question**: "Can I prove to Meta that every marketing message was sent only to users who explicitly opted in?"

**If No**: Compliance is broken - fix before scaling.

---

### 5. Human-in-the-Loop Escalation

**Principle**: Bots assist, not replace; escalation paths required for edge cases

**Why Non-Negotiable**:
- Nairobi commerce is relational (trust-based)
- Edge cases are common (payment mismatches, unclear orders, disputes)
- Automation fails without human override capability
- Research shows 60-80% containment is optimal (not 100%)

**What This Means**:
- ✅ **Must have**: Manual review queue for low-confidence orders/payments
- ✅ **Must have**: Agent takeover capability (human can intercept any conversation)
- ✅ **Must have**: Priority tagging (urgent, normal, low)
- ✅ **Must have**: Context preservation (human sees full conversation history)
- ❌ **Cannot do**: 100% automation with no human fallback
- ❌ **Cannot do**: Ignore edge cases (they become 20% of volume at scale)

**Validation Question**: "When an edge case occurs (payment mismatch, unclear order), can a human reviewer access the full context and resolve it?"

**If No**: Escalation path is broken - fix before scaling.

---

### 6. Multi-Tenant Data Model (From Day 1 Design)

**Principle**: Design for multiple SMEs from start (even if launching with one)

**Why Non-Negotiable**:
- Refactoring from single-tenant to multi-tenant is very costly
- Scales to 100+ SMEs without code changes
- Tenant isolation prevents data leaks (legal risk)

**What This Means**:
- ✅ **Must have**: `tenant_id` on all tables (orders, payments, customers, products)
- ✅ **Must have**: Row-Level Security (RLS) or equivalent isolation
- ✅ **Must have**: Config-driven tenant setup (add tenant = insert row, not code change)
- ✅ **Must have**: Tenant-scoped queries (never query across tenants without explicit design)
- ❌ **Cannot do**: Hardcode single business assumptions
- ❌ **Cannot do**: Share data across tenants without explicit design

**Validation Question**: "If I add a second trader tomorrow, do I need to change any code, or just insert a row in tenant_config?"

**If Code Change Required**: Multi-tenant design is broken - fix before scaling.

---

## 🔄 Flexible Adaptations (Implementation Choices)

**These can vary without breaking the core model. Adapt based on cost, rollout speed, and validation results.**

### 1. System of Record (Progressive Migration)

**Flexible Path**:
- **Week 1-4**: Google Sheets (free, fast setup, good for MVP validation)
- **Week 5+**: Supabase (KSh 3K/month, better for scale, real-time triggers)
- **Week 9+**: Optional ERPNext (KSh 2K-5K/month, full accounting features)

**Decision Framework**:
- **Start with Sheets if**: Budget < KSh 5K/month, need to validate fast, <50 orders/day
- **Migrate to Supabase if**: Budget available, need real-time, planning for scale
- **Add ERPNext if**: Need full accounting, compliance, or planning for 100+ traders

**Non-Negotiable Requirement**: Must have a migration path (don't lock data without export capability)

**Validation Question**: "Can I export all data from my current system of record?"

---

### 2. Orchestration Tool

**Flexible Options**:
- **n8n** (recommended): Self-hosted (free), visual workflows, native integrations
- **Zapier/Make.com**: Higher cost ($20-100/month), easier setup, less control
- **Custom middleware**: More control, but 10x development time

**Decision Framework**:
- **Use n8n if**: Cost-sensitive, need visual workflows, comfortable with self-hosting
- **Use Zapier/Make if**: Need faster setup, willing to pay premium, want managed service
- **Build custom if**: Need fine-grained control, have dedicated dev resources

**Non-Negotiable Requirement**: Must support webhook triggers, API calls, retry logic, error handling

**Validation Question**: "Can my orchestration tool handle 200+ orders/day with retries and error handling?"

---

### 3. WhatsApp Provider

**Flexible Options**:
- **SMSLeopard** (Kenya partner): Easier setup, local support, KSh 2K/month, good for MVP
- **Meta WhatsApp Cloud API** (direct): More features, global support, free tier, harder setup

**Decision Framework**:
- **Start with SMSLeopard if**: Need fast setup, want local support, MVP phase
- **Migrate to Meta Direct if**: Need advanced features, ready for production scale, want to reduce costs

**Non-Negotiable Requirement**: Must support webhooks, template messages, delivery status callbacks

**Validation Question**: "Can my WhatsApp provider handle webhooks, templates, and delivery callbacks?"

---

### 4. Bot Sophistication (Progressive Enhancement)

**Flexible Path**:
- **Week 1-2**: Manual order capture (no bot)
- **Week 3-4**: Keyword-based intent detection (simple, fast, 60-80% containment)
- **Week 13+**: AI-assisted routing (embeddings, better Swahili/Sheng support, 95%+ containment)

**Decision Framework**:
- **Start keyword-based if**: Need fast implementation, free, good enough for MVP (60% containment)
- **Add AI later if**: Containment rate drops below 60%, need better Swahili/Sheng support, have budget (KSh 10K/month for 1000 users)

**Non-Negotiable Requirement**: Must classify messages into intents (order, payment, support, catalog)

**Validation Question**: "Can my bot classify 60%+ of messages into correct intents?"

---

### 5. Template Count (Start Small, Grow)

**Flexible Path**:
- **Week 1-2**: 5 core templates (order_confirmation, payment_request, payment_confirmation, order_status, support_acknowledgment)
- **Week 9-12**: 15 templates (add post-purchase sequences, cart recovery, returns)
- **Week 13+**: 40-60 templates (A/B testing, optimization)

**Decision Framework**:
- **5 templates**: Good enough for MVP, fast Meta approval, low maintenance
- **15 templates**: Needed for full lifecycle automation (Stage 3)
- **40-60 templates**: Needed for maturity (Stage 4), A/B testing, optimization

**Non-Negotiable Requirement**: Must have at least 5 templates for core workflows

**Validation Question**: "Do I have templates for order confirmation, payment request, payment confirmation, order status, and support acknowledgment?"

---

### 6. ERP Integration Timing (Optional vs Required)

**Flexible Options**:
- **Start without ERPNext if**: Budget < KSh 5K/month, need to validate fast, <100 orders/day
- **Add ERPNext if**: Need full accounting, compliance (eTIMS), planning for 100+ traders, need audit trails

**Decision Framework**:
- **Supabase only if**: Need fast validation, budget-constrained, <100 orders/day
- **Add ERPNext if**: Need accounting features, compliance requirements, planning for scale

**Non-Negotiable Requirement**: Must have a system of record that persists orders, payments, customers (can be Supabase initially)

**Validation Question**: "Can I generate invoices, track payments, and produce audit trails for compliance?"

---

### 7. Multi-Rail Payments (Progressive Rollout)

**Flexible Path**:
- **Week 1-4**: M-Pesa only (90%+ of Kenyans use M-Pesa)
- **Week 9+**: Add PesaLink/Airtel Money (multi-rail routing)

**Decision Framework**:
- **M-Pesa only if**: Need fast setup, covers 90%+ of users, simpler implementation
- **Multi-rail if**: Payment failures exceed 10%, need to reduce payment friction, planning for scale

**Non-Negotiable Requirement**: Must have at least one payment method (M-Pesa is mandatory in Kenya)

**Validation Question**: "Can I process payments for at least 90% of my customers?"

---

### 8. Voice Note Transcription (Optional vs Required)

**Flexible Options**:
- **Manual transcription**: Free, slower, works for <50 orders/day
- **Google Speech-to-Text**: ~KSh 15/month for 100K requests, faster, needed for scale

**Decision Framework**:
- **Manual if**: <50 orders/day, budget-constrained, voice notes <20% of orders
- **Automate if**: Voice notes >20% of orders, need faster processing, have budget

**Non-Negotiable Requirement**: Must handle voice notes (Gikomba/Eastleigh reality), but can be manual initially

**Validation Question**: "Can I process voice note orders, even if manually?"

---

## Decision Framework: When to Iterate

### Start Simple (MVP Validation - Week 1-4)

**Flexible Choices**:
- ✅ Google Sheets for data storage
- ✅ n8n self-hosted (free)
- ✅ SMSLeopard for WhatsApp (KSh 2K/month)
- ✅ Keyword-based bot (free)
- ✅ 5 templates (fast approval)
- ✅ M-Pesa only (90% coverage)
- ✅ Manual voice note transcription
- ✅ Supabase only (no ERPNext initially)

**Total Cost**: KSh 0-5K/month (free tiers + SMSLeopard)

**Validation Goals**: Prove order capture, payment matching, basic automation works

**Non-Negotiables Check**: ✅ All 6 non-negotiables preserved

---

### Scale (When Validation Works - Week 5-8)

**Flexible Choices**:
- ✅ Supabase migration (KSh 3K/month)
- ✅ 15 templates (full lifecycle)
- ✅ Payment retry logic
- ✅ Post-purchase sequences
- ✅ Basic analytics

**Total Cost**: KSh 5K-10K/month

**Scale Goals**: Handle 200-400 orders/day, 95%+ payment automation

**Non-Negotiables Check**: ✅ All 6 non-negotiables preserved

---

### Mature (When Ready for 100+ Traders - Week 9-12+)

**Flexible Choices**:
- ✅ ERPNext integration (KSh 2K-5K/month)
- ✅ 40-60 templates (A/B testing)
- ✅ Multi-rail payments
- ✅ AI-assisted routing (KSh 10K/month)
- ✅ Voice note automation
- ✅ Comprehensive analytics

**Total Cost**: KSh 20K-30K/month

**Maturity Goals**: Handle 1000+ users, 18:1+ ROI, data-driven optimization

**Non-Negotiables Check**: ✅ All 6 non-negotiables preserved

---

## Red Flags: When Flexibility Becomes Risk

**Watch for these signals that flexibility is creating technical debt:**

1. ❌ **No migration path**: Locking data into Google Sheets without Supabase migration plan
2. ❌ **Single-tenant assumptions**: Hardcoding business logic that breaks with 2nd trader
3. ❌ **No consent tracking**: Skipping consent records (Meta will block you)
4. ❌ **No payment reconciliation**: Manual matching (doesn't scale)
5. ❌ **100% automation**: No human escalation (edge cases will break you)

**If you see these, pause and address the non-negotiables before scaling.**

---

## Validation Checklist: Pre-Launch

**Before launching, confirm all non-negotiables are preserved:**

- [ ] **Three-layer separation**: Can I access all business data independently of WhatsApp?
- [ ] **Phone number as identity**: Can I find a customer's complete history using only phone number?
- [ ] **Payment reconciliation**: Can I match 95%+ of M-Pesa payments automatically?
- [ ] **Consent tracking**: Can I prove compliance for every marketing message?
- [ ] **Human escalation**: Can human reviewers access full context for edge cases?
- [ ] **Multi-tenant design**: Can I add a second trader without code changes?

**If any box is unchecked, fix before scaling.**

---

## Summary

**Non-Negotiables (Architectural Guardrails)**:
1. Three-layer separation (Channels → Orchestration → System of Record)
2. Phone number as primary identity
3. Automated payment reconciliation (M-Pesa webhooks)
4. Explicit consent tracking (transactional vs marketing)
5. Human-in-the-loop escalation (review queue)
6. Multi-tenant data model (from day 1 design)

**Flexible Adaptations (Implementation Choices)**:
- System of record: Sheets → Supabase → ERPNext (progressive migration)
- Orchestration: n8n, Zapier, Make, or custom (tool choice)
- WhatsApp provider: SMSLeopard vs Meta direct (vendor choice)
- Bot sophistication: Manual → keyword → AI (progressive enhancement)
- Template count: 5 → 15 → 40-60 (grow with usage)
- ERP timing: Optional early, required later (based on needs)
- Payments: M-Pesa first, multi-rail later (progressive rollout)
- Voice notes: Manual initially, automate when volume justifies (cost-benefit)

**Key Principle**: The architecture, identity model, payments, consent, and tenant isolation are fixed. Tooling, depth of automation, and rollout sequence remain intentionally flexible.

---

## References

- **Detailed Architecture**: [`WAAS_ARCHITECTURE.md`](../architecture/WAAS_ARCHITECTURE.md) - Three-layer architecture design
- **Build Plan**: [`BUILD_PLAN.md`](./BUILD_PLAN.md) - Stage-gated execution plan
- **Workflows**: [`WORKFLOWS.md`](./WORKFLOWS.md) - Business processes and user journeys
- **Technical KB**: [`WhatsApp_Commerce_Technical_KB.md`](./WhatsApp_Commerce_Technical_KB.md) - Integration guides

---

**Last Updated**: 2026-01-09  
**Status**: Core architectural principles - use as decision-making framework  
**Next Review**: After Week 1 validation (confirm principles hold in practice)
