# Do Not Build (Save Months)

**Things that feel clever but will waste months of your time.**

Based on lessons from failed WhatsApp-commerce implementations globally (India, Brazil, Nigeria, Kenya). This is the "anti-pattern" guide.

**Reference**: This complements [`WAAS_ARCHITECTURE.md`](./architecture/WAAS_ARCHITECTURE.md) by explicitly calling out what NOT to build.

---

## ❌ Don't Build: Custom WhatsApp Bot (Full Conversation AI)

**What It Sounds Like:**
- "Let's build an AI chatbot that handles all customer conversations"
- "We'll use GPT-4 to understand customer intent and respond automatically"

**Why It Fails:**
- Violates Meta's ToS (no API access to full conversation history)
- Requires massive training data (you don't have it yet)
- Breaks when edge cases appear (payment disputes, delivery issues)
- Users expect human escalation (Nairobi commerce is relational)
- Cost: Months of development, constant tuning, still breaks

**What To Build Instead:**
- ✅ Simple keyword-based classification (order, payment, support)
- ✅ Structured quick replies (YES, NO, CONFIRM, REJECT)
- ✅ Human escalation paths (agent takeover)
- ✅ Use AI later (Stage 5) for intent classification, not full conversations

**Time Saved**: 3-6 months

---

## ❌ Don't Build: Conversation Storage in n8n/ERPNext

**What It Sounds Like:**
- "Let's store all WhatsApp messages in our database for analytics"
- "We'll build a conversation history viewer in ERPNext"

**Why It Fails:**
- Violates Meta's data residency rules (conversations must stay in Meta's system)
- Massive storage costs (millions of messages)
- Privacy compliance issues (GDPR, Kenya Data Protection Act)
- You don't need full history - you need message → action → outcome

**What To Build Instead:**
- ✅ Store message logs (who sent what, when, delivery status)
- ✅ Store business actions (order created, payment confirmed)
- ✅ Store audit trail (what happened, not full conversation text)
- ✅ Use Meta's webhook logs for debugging (if needed)

**Time Saved**: 2-3 months

---

## ❌ Don't Build: Custom ERP from Scratch

**What It Sounds Like:**
- "Let's build our own order management system"
- "We'll use MongoDB/Postgres and build custom APIs"

**Why It Fails:**
- Accounting logic is hard (double-entry, reconciliation, VAT)
- Permissions are complex (merchant isolation, agent roles)
- Audit trails are critical (banks, regulators will ask)
- You'll rebuild what ERPNext already does (badly)

**What To Build Instead:**
- ✅ Use ERPNext (or Supabase + custom logic if ERPNext too heavy)
- ✅ Customize DocTypes (Customer, Order, Payment)
- ✅ Build on proven foundation (accounting, permissions, audit)

**Time Saved**: 6-12 months

---

## ❌ Don't Build: WhatsApp-Only Platform (No SMS Fallback)

**What It Sounds Like:**
- "WhatsApp is enough, we don't need SMS"
- "SMS is expensive, let's skip it"

**Why It Fails:**
- WhatsApp delivery fails (data bundles run out, phones offline)
- Lost transactions = lost revenue
- Kenya has poor data connectivity in some areas
- Users expect reliability (payment confirmations must arrive)

**What To Build Instead:**
- ✅ WhatsApp first (better UX, lower cost)
- ✅ SMS fallback (automatic on WhatsApp timeout/failure)
- ✅ Route by message type (OTP → SMS, order update → WhatsApp)

**Time Saved**: 1-2 months (rebuilding after WhatsApp failures)

---

## ❌ Don't Build: Payment Matching Without Tolerance

**What It Sounds Like:**
- "We'll match M-Pesa payments by exact amount"
- "If amount doesn't match exactly, flag for review"

**Why It Fails:**
- Users send slightly different amounts (KSh 500.50 vs KSh 500)
- Network fees vary (M-Pesa charges vary by transaction)
- Exact matching = too many false negatives
- Manual review queue explodes

**What To Build Instead:**
- ✅ Match by phone + amount (±50 KSh tolerance)
- ✅ If multiple matches → manual review
- ✅ If no match → log to daily_logs for reconciliation
- ✅ Auto-match when confidence high (one match, amount within tolerance)

**Time Saved**: 1 month (fixing false negatives)

---

## ❌ Don't Build: No Consent Tracking

**What It Sounds Like:**
- "We'll send marketing messages to everyone"
- "Consent tracking is too complex, we'll add it later"

**Why It Fails:**
- Meta blocks your account (violations = permanent ban)
- Regulatory fines (Kenya Data Protection Act)
- User trust destroyed (spam = uninstall)
- Can't prove compliance (banks, partners ask)

**What To Build Instead:**
- ✅ Track consent from day one (consent table)
- ✅ Implied consent for transactional (order updates, payment confirmations)
- ✅ Explicit consent for marketing (opt-in required)
- ✅ Log all consent changes (audit trail)

**Time Saved**: 2-3 months (rebuilding after account block)

---

## ❌ Don't Build: Hardcoded Business Logic in n8n

**What It Sounds Like:**
- "We'll hardcode order statuses in n8n workflows"
- "Business rules live in n8n, not ERPNext"

**Why It Fails:**
- Can't change rules without editing workflows (slow iteration)
- No audit trail (who changed what, when)
- Can't test business logic separately
- Becomes spaghetti workflows (unmaintainable)

**What To Build Instead:**
- ✅ Business logic in ERPNext (DocTypes, validations, workflows)
- ✅ n8n orchestrates (triggers ERPNext, handles retries)
- ✅ n8n is stateless (reads state from ERPNext, triggers actions)

**Time Saved**: 2-4 months (refactoring hardcoded logic)

---

## ❌ Don't Build: No Human Escalation Paths

**What It Sounds Like:**
- "Bots will handle everything automatically"
- "We'll add human support later if needed"

**Why It Fails:**
- Edge cases are common (payment mismatches, delivery disputes)
- Users expect human help (Nairobi commerce is relational)
- Bots fail silently (no one notices until revenue drops)
- Trust requires human touch (especially for disputes)

**What To Build Instead:**
- ✅ Agent takeover from day one (even if unused)
- ✅ Manual override flags (force send, force retry, suppress)
- ✅ Priority tagging (urgent, normal, low)
- ✅ Daily review queue (daily_logs for manual intervention)

**Time Saved**: 1-2 months (rebuilding after bot failures)

---

## ❌ Don't Build: Single Business Assumptions

**What It Sounds Like:**
- "We're building for one merchant, we'll scale later"
- "Hardcode merchant ID, we'll refactor later"

**Why It Fails:**
- Refactoring is painful (data migration, API changes)
- Multi-merchant is core architecture (not a feature add-on)
- You'll need it sooner than you think (Week 3-4)
- Hardcoded assumptions break everything

**What To Build Instead:**
- ✅ Design for multi-merchant from day one (merchant_id everywhere)
- ✅ Merchant isolation (permissions, data separation)
- ✅ Agent model (merchant can have multiple agents)
- ✅ Outlet model (merchant can have multiple locations)

**Time Saved**: 3-6 months (refactoring single-business code)

---

## ❌ Don't Build: No Cost Tracking

**What It Sounds Like:**
- "We'll track costs later when we scale"
- "WhatsApp is cheap, we don't need cost controls"

**Why It Fails:**
- Costs scale fast (1000 trades/day = KSh 2,880/day = KSh 86,400/month)
- Can't optimize what you don't measure
- Margins die silently (costs grow faster than revenue)
- Investors/partners ask for unit economics

**What To Build Instead:**
- ✅ Track cost per message (message_logs.cost_kes)
- ✅ Track cost per trade (aggregate daily)
- ✅ Cost control levers (suppress non-critical, batch notifications)
- ✅ Daily cost reports (ERPNext custom report)

**Time Saved**: 1-2 months (rebuilding cost tracking)

---

## ❌ Don't Build: No Idempotency

**What It Sounds Like:**
- "Webhooks won't duplicate"
- "We'll handle duplicates if they happen"

**Why It Fails:**
- Webhooks duplicate (network retries, provider bugs)
- Duplicate orders = lost revenue
- Duplicate payments = accounting nightmare
- Can't prove what happened (disputes)

**What To Build Instead:**
- ✅ Idempotency keys everywhere (message_id, receipt_number)
- ✅ Check before processing (query ERPNext first)
- ✅ Log duplicate attempts (audit trail)
- ✅ Never process same webhook twice

**Time Saved**: 1-2 months (fixing duplicate bugs)

---

## ❌ Don't Build: No Audit Trail

**What It Sounds Like:**
- "We'll add logging later"
- "Audit trails are for big companies"

**Why It Fails:**
- Banks ask for payment trails (partnerships require compliance)
- Regulators ask for consent logs (data protection)
- Disputes require proof (who did what, when)
- Can't debug production issues (no logs = blind)

**What To Build Instead:**
- ✅ Audit logs from day one (audit_logs table)
- ✅ Log all business actions (order created, payment confirmed)
- ✅ Log all message sends (message_logs table)
- ✅ Log all consent changes (consent table with timestamps)

**Time Saved**: 2-3 months (rebuilding audit trail)

---

## ❌ Don't Build: SaaS-Only Stack

**What It Sounds Like:**
- "We'll use Zapier/Make.com for automation"
- "We'll use Airtable for database"
- "We'll use Twilio for SMS"

**Why It Fails:**
- Costs explode at scale (Zapier: $50/month → $500/month → $5,000/month)
- Data lock-in (can't export, can't migrate)
- No control (provider changes, downtime, pricing)
- Compliance issues (data residency, GDPR)

**What To Build Instead:**
- ✅ Self-hosted n8n (cost: KSh 5,000/month, scales infinitely)
- ✅ Self-hosted ERPNext (cost: KSh 3,000/month, own your data)
- ✅ Local SMS providers (SMSLeopard, AfricasTalking - Kenya-friendly)
- ✅ Own your infrastructure (control, cost, compliance)

**Time Saved**: 6-12 months (migrating from SaaS to self-hosted)

---

## ❌ Don't Build: WhatsApp Flows Before Templates

**What It Sounds Like:**
- "Let's build WhatsApp Flows for product catalog"
- "Flows are better UX than templates"

**Why It Fails:**
- Flows require approval (longer than templates)
- Flows are complex (more failure points)
- Templates are sufficient for MVP (order confirmation, payment link)
- Flows can come later (Week 3-4)

**What To Build Instead:**
- ✅ Start with templates (5 core templates for MVP)
- ✅ Get templates approved first (24-48 hours)
- ✅ Add Flows later (Week 3-4) when templates are stable
- ✅ Use Flows for complex interactions (product catalog, quantity selector)

**Time Saved**: 1-2 weeks (waiting for Flow approval)

---

## ❌ Don't Build: No Error Handling

**What It Sounds Like:**
- "We'll add error handling later"
- "Errors won't happen in production"

**Why It Fails:**
- External APIs fail (Meta, M-Pesa, SMS providers)
- Network timeouts happen (Kenya connectivity is unreliable)
- Silent failures = lost revenue (orders not created, payments not confirmed)
- Can't debug without error logs

**What To Build Instead:**
- ✅ Error handling from day one (try/catch in every workflow)
- ✅ Log all errors to daily_logs (requires_review=true)
- ✅ Retry logic (3 attempts, exponential backoff)
- ✅ Fallback paths (WhatsApp → SMS, primary → secondary provider)

**Time Saved**: 1-2 months (fixing production bugs)

---

## Summary: What NOT to Build

**High-Impact Anti-Patterns (Save 6+ months):**
1. ❌ Custom ERP from scratch
2. ❌ SaaS-only stack (Zapier, Airtable, Twilio)
3. ❌ Single business assumptions
4. ❌ Custom WhatsApp bot (full AI conversations)

**Medium-Impact Anti-Patterns (Save 2-4 months):**
5. ❌ Hardcoded business logic in n8n
6. ❌ No consent tracking
7. ❌ Conversation storage in database
8. ❌ No audit trail

**Low-Impact Anti-Patterns (Save 1-2 months):**
9. ❌ WhatsApp-only (no SMS fallback)
10. ❌ Payment matching without tolerance
11. ❌ No human escalation paths
12. ❌ No cost tracking
13. ❌ No idempotency
14. ❌ No error handling
15. ❌ WhatsApp Flows before templates

---

## What TO Build Instead

**Follow the WaaS Architecture:**
- ✅ ERPNext = System of Record (truth, money, compliance)
- ✅ n8n = Orchestration (logic, routing, timing)
- ✅ WhatsApp/SMS = Channels (replaceable)

**Follow the First 7 Workflows:**
- ✅ `classify_message` (foundation)
- ✅ `check_consent` (protection)
- ✅ `send_whatsapp` (core messaging)
- ✅ `send_sms_fallback` (reliability)
- ✅ `log_message` (audit trail)
- ✅ `reconcile_payment` (trust)
- ✅ `send_payment_confirmation` (transparency)

**Follow the Integration Capabilities Matrix:**
- ✅ Build only what's in "MUST-HAVE" column
- ✅ Skip "NICE-TO-HAVE" until MVP is stable
- ✅ Test each integration before moving to next

---

## Mental Model

**If it feels clever, it's probably fragile.**
**If it feels boring, it will scale.**

**Examples:**
- ❌ Clever: "AI chatbot handles all conversations"
- ✅ Boring: "Keyword classification + human escalation"

- ❌ Clever: "Build custom ERP from scratch"
- ✅ Boring: "Use ERPNext, customize DocTypes"

- ❌ Clever: "WhatsApp-only platform"
- ✅ Boring: "WhatsApp + SMS fallback"

---

## References

- **WaaS Architecture**: [`WAAS_ARCHITECTURE.md`](./architecture/WAAS_ARCHITECTURE.md)
- **First 7 Workflows**: [`FIRST_7_WORKFLOWS.md`](./FIRST_7_WORKFLOWS.md)
- **Integration Capabilities Matrix**: [`INTEGRATION_CAPABILITIES_MATRIX.md`](./INTEGRATION_CAPABILITIES_MATRIX.md)
- **Build Plan**: [`BUILD_PLAN.md`](./core/BUILD_PLAN.md)

---

**Last Updated**: 2026-01-09  
**Status**: Anti-patterns documented, time-saving guide complete  
**Next Review**: After MVP launch (validate which anti-patterns were avoided)

