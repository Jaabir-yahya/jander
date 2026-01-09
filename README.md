# WhatsApp-First Commerce for Nairobi Informal Traders

**Evidence-based, production-ready system for Gikomba, Eastleigh, and Toi markets.**

Built with Cursor Pro + n8n + Supabase following proven patterns from India, Brazil, Nigeria, and Indonesia.

---

## Quick Start

1. **Prerequisites:** Complete [SETUP.md](./SETUP.md) checklist (~40 minutes)
2. **Implementation:** Follow [GETTING_STARTED.md](./GETTING_STARTED.md) for detailed step-by-step guide
3. **Week 1 Plan:** See [docs/WEEK1_EXECUTION_PLAN.md](./docs/WEEK1_EXECUTION_PLAN.md) for comprehensive execution plan
4. **Documentation:** Start with [docs/README.md](./docs/README.md) for navigation
5. **Roadmap:** Review [docs/BUILD_PLAN.md](./docs/BUILD_PLAN.md) for week-by-week milestones

---

## Project Structure

```
jander/
├── .cursor-rules              # AI development rules (mandatory)
├── docs/                      # Core documentation (5 files)
│   ├── README.md              # Overview & navigation
│   ├── ARCHITECTURE.md        # System design, schema, integrations
│   ├── WORKFLOWS.md           # Business processes, user journeys
│   ├── BUILD_PLAN.md          # Week-by-week execution plan
│   └── CONTEXT.md             # Research, failure modes, evidence
├── apps/
│   ├── n8n/                   # Exported n8n workflows
│   ├── scripts/               # Node.js webhook receivers
│   └── supabase/              # Migrations, seeds
│       └── migrations/        # SQL migration files
├── traders/                   # Onboarding templates, materials
├── templates/                 # WhatsApp message templates
└── tests/                     # Test cases, validation scripts
```

---

## Tech Stack

**Week 1-4 (MVP):**
- Google Sheets (data storage)
- WhatsApp Business Cloud API
- n8n (automation workflows)
- M-Pesa Daraja (sandbox)

**Week 5+ (Production):**
- Supabase (Postgres database)
- Whalesync (Sheets ↔ Supabase sync)
- M-Pesa Daraja (live)
- Optional: ERPNext/Frappe (Week 9+)

---

## Documentation

**Start here:** [docs/00_START_HERE.md](./docs/00_START_HERE.md) - Master documentation index

**Core Documents:**
- [docs/core/PROJECT_MASTER.md](./docs/core/PROJECT_MASTER.md) - Complete project context
- [docs/core/BUILD_PLAN.md](./docs/core/BUILD_PLAN.md) - Execution roadmap (Weeks 1-12)
- [docs/core/ARCHITECTURE.md](./docs/core/ARCHITECTURE.md) - System design
- [docs/core/WORKFLOWS.md](./docs/core/WORKFLOWS.md) - Business processes

**For Tomorrow:**
- [docs/guides/WEEK1_ACTION_PLAN.md](./docs/guides/WEEK1_ACTION_PLAN.md) ⭐ **Complete step-by-step guide**

**See [docs/README.md](./docs/README.md) for full documentation structure.**

---

## Development Workflow

1. **Context Load:** `Cmd+I → "@docs/ARCHITECTURE.md @docs/WORKFLOWS.md"`
2. **Build:** Use Week X commands from BUILD_PLAN.md
3. **Test:** Always include Nairobi edge cases (voice notes, spotty 4G, payment mismatches)
4. **Deploy:** Export n8n workflows, update Sheets permissions
5. **Document:** Update relevant doc in `docs/` folder

---

## Success Metrics (Week 12)

- 50+ active traders
- 200+ orders/week
- 90%+ payment reconciliation accuracy
- <5% daily "lost orders" due to chat overload
- KSh 5K–10K MRR

---

## Cost Curve

- **Month 1-3:** KSh 0 (all free tiers)
- **Month 4-6:** KSh 0 (still free)
- **Month 7-9:** KSh 7K/mo (n8n $20 + Supabase $25)
- **Month 10-12:** KSh 15K/mo (scaling costs)
- **Revenue by Month 6:** KSh 10K MRR (covers costs)

---

**Ready to build?** 
1. Complete [SETUP.md](./SETUP.md) prerequisites checklist
2. Follow [GETTING_STARTED.md](./GETTING_STARTED.md) for step-by-step implementation
3. Review [docs/WEEK1_EXECUTION_PLAN.md](./docs/WEEK1_EXECUTION_PLAN.md) for detailed execution plan
4. Check [tests/test-scenarios.md](./tests/test-scenarios.md) for test cases
5. Read [SECURITY.md](./SECURITY.md) for security best practices

---

## Security

⚠️ **Important:** This repository handles sensitive credentials. See [SECURITY.md](./SECURITY.md) for:
- Environment variable management
- API key protection
- Credentials storage best practices
- What to never commit to Git

