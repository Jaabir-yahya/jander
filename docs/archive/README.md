# WhatsApp-First Commerce System for Nairobi Informal Traders

**Evidence-based, production-ready, Nairobi-specific build plan for solo developers.**

## Quick Overview

Build a WhatsApp-first commerce system for Nairobi informal traders (Gikomba, Eastleigh, Toi markets) in 12 weeks, starting lightweight (Google Sheets/Airtable MVP) and scaling to production backend (Supabase → ERPNext/Frappe) as validation milestones are hit.

## Key Principles

- **WhatsApp is the front door, not the system of record.**
- **M-Pesa reconciliation is non-negotiable.**
- **Chat overload kills 70% of pilots; minimal structure prevents this.**
- **Prove catalog+orders+payment before adding logistics/accounting.**
- **Traders stay in WhatsApp; backend stays invisible.**

## Success Metrics (Week 12)

- 50+ active traders
- 200+ orders/week
- 90%+ payment reconciliation accuracy
- <5% daily "lost orders" due to chat overload
- KSh 5K–10K MRR (freemium conversions)

## Documentation Structure

This project uses core reusable documents that get updated as we build:

**Core Documents:**
1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System design, tech stack, data schema, integrations
2. **[WORKFLOWS.md](./WORKFLOWS.md)** - Business processes, user journeys, lifecycle stages
3. **[BUILD_PLAN.md](./BUILD_PLAN.md)** - Stage-gated 5-stage lifecycle execution plan, milestones, checklists
4. **[CONTEXT.md](./CONTEXT.md)** - Research findings, failure modes, Nairobi adaptations, evidence
5. **[WEEK1_EXECUTION_PLAN.md](./WEEK1_EXECUTION_PLAN.md)** - Detailed Week 1 execution plan with reverse-pyramid model strategy

**Supporting Documents:**
6. **[WAAS_ARCHITECTURE.md](./WAAS_ARCHITECTURE.md)** - **Three-layer architecture: ERPNext → n8n → Channels (WhatsApp/SMS)**
7. **[TRADE_FACILITATOR_ARCHITECTURE.md](./TRADE_FACILITATOR_ARCHITECTURE.md)** - Hub-and-spoke model: Single WABA orchestrates trades between buyers and sellers
8. **[INTEGRATION_CAPABILITIES_MATRIX.md](./INTEGRATION_CAPABILITIES_MATRIX.md)** - Detailed capability matrix with testing checklists (MUST-HAVE → NICE-TO-HAVE)
9. **[INTEGRATION_CAPABILITIES.md](./INTEGRATION_CAPABILITIES.md)** - Maximum capabilities required from each integration for automation and testing
10. **[FIRST_7_WORKFLOWS.md](./FIRST_7_WORKFLOWS.md)** - Priority order for n8n workflows (build order for solo dev)
11. **[DO_NOT_BUILD.md](./DO_NOT_BUILD.md)** - Anti-patterns guide (things that waste months - save 6-12 months)
12. **[LIFECYCLE_STAGES.md](./LIFECYCLE_STAGES.md)** - Detailed 5-stage lifecycle definitions with research citations
13. **[TEMPLATE_REGISTRY.md](./TEMPLATE_REGISTRY.md)** - Template governance system for Stage 1 foundation
14. **[ANALYTICS_SCHEMA.md](./ANALYTICS_SCHEMA.md)** - Metrics definitions and KPI tracking structure

**Week 1 Focus**: See [WEEK1_EXECUTION_PLAN.md](./WEEK1_EXECUTION_PLAN.md) for comprehensive Day 1–5 tasks, evidence-based approach from India/Nigeria/Brazil, and reverse-pyramid model (1 growth SME → 10 Eastleigh micro-sellers).

## Tech Stack Evolution

- **Weeks 1–4:** Google Sheets + Airtable + WhatsApp Business Cloud API + n8n automation
- **Weeks 5–8:** Supabase (Postgres) + Whalesync (Sheet-to-DB sync) + M-Pesa Daraja
- **Weeks 9–12:** Optional ERPNext/Frappe integration for multi-vendor scale

## Quick Start

1. Read [WEEK1_EXECUTION_PLAN.md](./WEEK1_EXECUTION_PLAN.md) for detailed Week 1 tasks and strategy
2. Review [BUILD_PLAN.md](./BUILD_PLAN.md) for overall stage-gated roadmap
3. Review [ARCHITECTURE.md](./ARCHITECTURE.md) for system design decisions
4. Understand [WORKFLOWS.md](./WORKFLOWS.md) for business processes
5. Reference [CONTEXT.md](./CONTEXT.md) for why decisions were made (evidence from India/Nigeria/Brazil)
6. Check [INTEGRATION_CAPABILITIES.md](./INTEGRATION_CAPABILITIES.md) for integration requirements and tests

## Weekly Research & Validation

**Friday Check-Ins:** Use [WEEKLY_CHECKIN.md](./WEEKLY_CHECKIN.md) template to share:
- Week X results and metrics
- What worked / what broke
- Decisions needed (Supabase timing, API alternatives, etc.)
- Research requests (attach BUILD_PLAN.md + CONTEXT.md)

**Research Cadence:**
```
Every Friday: Cmd+I → "@docs/CONTEXT.md Audit Week X vs failure modes"
→ Copy output → Share with research validator
→ Updates applied to CONTEXT.md + BUILD_PLAN.md
```

---

**Note:** These documents are living documents. Update them as you build, don't create new redundant markdown files. Keep all documentation in this `docs/` folder.

