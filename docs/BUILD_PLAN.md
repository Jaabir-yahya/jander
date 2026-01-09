# Build Plan & Execution Guide

**Week-by-week execution plan, milestones, checklists, and metrics.**

---

## Timeline Overview

| Phase | Weeks | Goal | Traders | Orders/Week | Metrics |
|-------|-------|------|---------|-------------|---------|
| **MVP Setup** | 1–2 | Sheets + WhatsApp API tested | 5 | 20–50 | Chat overload, lost messages |
| **Validation** | 3–4 | Proof of concept: payment matching works; no major churn | 10–20 | 50–100 | Churn rate, payment mismatch %, adoption friction |
| **Scaling** | 5–8 | Migrate to Supabase; add automation; start paid tier | 30–50 | 200–400 | MRR, retention, dispatch speed |
| **Refinement** | 9–12 | Stabilize; explore ERPNext integration; expand to 2nd market | 50–100 | 500+ | CAC, LTV, NPS |

---

## Week-by-Week Milestones

### Week 1

> **📋 Detailed Week 1 Execution Plan**: See [`WEEK1_EXECUTION_PLAN.md`](./WEEK1_EXECUTION_PLAN.md) for comprehensive day-by-day tasks, evidence-based approach, and reverse-pyramid model strategy.

**Quick Summary:**
- **Goal**: Validate 3 core hacks (WhatsApp → ERPNext, structured parsing, STK push + match) with 1 growth SME owner
- **Duration**: 5 days
- **Cost**: KSh 0 (free tier)
- **Target**: 1 growth SME (boutique/grocery chain, CBD/Westlands) → prepare Week 2 expansion to 10 Eastleigh micro-sellers

**Day-by-Day Overview:**

**Day 1: WhatsApp Webhook + Order Parse Engine**
- Build order parse engine (text + voice + image)
- Extract structured data from WhatsApp messages
- Test cases: happy path, voice note, Sheng text, image OCR

**Day 2: ERPNext Bridge (Parse → ERPNext API)**
- Auto-create ERPNext Sales Order from parsed order
- Generate invoice (eTIMS-ready)
- Handle product matching, customer creation

**Day 3: M-Pesa STK Push + Payment Matching**
- Send STK push for payment
- Auto-match callback → update ERPNext
- WhatsApp payment confirmation with invoice PDF

**Day 4: Human-in-Loop Review Queue**
- Low-confidence orders → review queue
- Cyber-cafe youth reviewer fixes edge cases
- Learning loop: Track corrections → improve patterns

**Day 5: Pilot Onboarding + Success Metrics**
- Onboard 1 growth SME owner
- Process 3–5 test orders end-to-end
- Validate 3 core hacks + prepare Week 2 expansion

**Checklist:**
- [ ] WhatsApp Business API (SMSLeopard) webhook configured
- [ ] Order parse engine built (text + voice + image)
- [ ] ERPNext instance ready (Frappe Cloud or self-hosted)
- [ ] ERPNext API bridge functional (Sales Order creation)
- [ ] Daraja STK push integration working
- [ ] Payment matching logic (callback → ERPNext update)
- [ ] Human review queue system (Google Sheets or Supabase)
- [ ] 1 growth SME owner onboarded + 3–5 test orders processed

**Goal:** Prove WhatsApp → ERPNext → M-Pesa → invoice flow works with 1 growth SME; validate 3 core hacks; prepare Week 2 expansion to Eastleigh micro-sellers

### Week 2
- [ ] n8n workflows live: order capture → confirmation, payment webhook → match
- [ ] 5 Gikomba traders onboarded (formal signup, brief training)
- [ ] 20+ real orders; payment matching accuracy measured
- **Goal:** Identify biggest friction points (chat overload? payment mismatches?)

### Week 3
- [ ] Pivot: Switch to Airtable forms (if multi-staff feedback asks for it)
- [ ] Add simple daily audit: list of "missed" chats, payment mismatches
- [ ] Start paid tier design: KSh 200/mo for daily profit summary
- [ ] 10–15 traders; ~50 orders/week
- **Goal:** Prove retention; measure free → paid conversion

### Week 4
- [ ] Decide: Ship Sheets-only to 20 more traders, or migrate early to Supabase?
- [ ] If sheets: Add M-Pesa till statement import (manual CSV daily)
- [ ] If Supabase: Begin migration prep
- [ ] 20 traders; ~100 orders/week
- **Goal:** Traction proof; secure first 2–3 paid signups

### Week 5
- [ ] Supabase live; Whalesync syncing sheets ↔ DB in real-time
- [ ] Daraja live: M-Pesa webhook auto-matches payments
- [ ] Payment reconciliation: Audit weekly; 90%+ match rate
- [ ] 30 traders; ~150 orders/week
- **Goal:** Stability; payment trust established

### Week 6–8
- [ ] Scale onboarding: Recruit 2 market champions (Gikomba + Eastleigh); they recruit peers
- [ ] Add low-priority features: Reorder quick-replies, monthly profit emails, basic CRM (notes on customers)
- [ ] Paid tier: Email + WhatsApp invoices (KSh 500/mo)
- [ ] 50+ traders; 300+ orders/week; KSh 2K–5K MRR
- **Goal:** Market fit validated; growth loop working

### Week 9–12
- [ ] Optional: ERPNext setup for stock tracking + eTIMS (if traders ask)
- [ ] Expand to 2nd market (Toi, River Road) via champions
- [ ] Premium tier design: Multi-staff roles, dispatch API (Leta integration), KSh 2K/mo
- [ ] 100 traders; 500+ orders/week; KSh 8K–15K MRR
- **Goal:** Fundraise-ready; unit economics proven

---

## Key Metrics to Track Weekly

### Adoption
- New traders signed up
- Active traders (≥1 order/week)
- Churn rate (traders gone inactive)

### Order Flow
- Orders captured per day
- Orders with payment matched (%)
- Time from order → payment confirm (hours)
- Time from payment confirm → dispatch (hours)

### Payment Reconciliation
- % of till transactions matched to orders automatically
- % requiring manual review
- Unmatched amount (KSh)
- Time to resolve mismatches

### Chat Health
- "Missed orders" (orders lost because trader didn't see WhatsApp)
- Messages per trader per day (average)
- Complaints about "order confusion"

### Revenue
- Orders/week
- Avg order value (KSh)
- Revenue/week (KSh)
- MRR from paid tier
- Churn rate (%)

### Goals (by Week 12)
- 100 active traders
- 500+ orders/week
- 90%+ payment match rate
- <5% weekly churn
- KSh 10K+ MRR (freemium + paid)

---

## Pilot Checklist (Week 1 Pre-Launch)

Before onboarding first 5 traders:
- [ ] Meta developer account verified + WhatsApp Business number assigned
- [ ] Webhook tested locally; can receive incoming messages and log them
- [ ] Google Sheets schema created + shared with team
- [ ] n8n workflows drafted (not live yet; test flows documented)
- [ ] M-Pesa Daraja sandbox account live; test C2B flow works
- [ ] Training video recorded (5 mins): "How to use the order system"
- [ ] Support channel set up (WhatsApp group, email, or phone)
- [ ] Success metrics dashboard created (even if manual; track weekly)
- [ ] Risk log started: List of identified issues + how you'll fix them

---

## Safeguard Checklist (Risk Mitigation)

### Before Go-Live (Week 1)
- [ ] **Chat Overload:** WhatsApp Business account set up (dedicated number, not personal)
- [ ] **No Audit Trail:** Every order creates a unique order_id in sheet/DB; not erased
- [ ] **Payment Mismatch:** Daraja webhook tested; M-Pesa refs extracted correctly
- [ ] **Over-Complex:** Schema has max ~60 columns; traders see <10 fields per order form
- [ ] **Multi-Staff Chaos:** Only 1–2 people have edit access to sheets; audit log of edits enabled
- [ ] **Fraud:** API keys stored securely (not hardcoded in scripts); WhatsApp verified account

### During Pilot (Weeks 2–4)
- [ ] **Weekly Audit:** Every Monday, review "missed orders" log; identify patterns
- [ ] **Payment Audit:** Every Friday, download M-Pesa till statement; compare to Confirmed orders
- [ ] **Feedback Loop:** Weekly 15-min call with 2–3 traders; ask: "What broke this week?"
- [ ] **Churn Check:** If trader hasn't ordered in 5 days, check in

### Before Scaling (Week 5)
- [ ] **Supabase Security:** Enable Row-Level Security (RLS); traders can only see their own data
- [ ] **eTIMS Compliance:** Invoice generation templates reviewed for KRA compliance
- [ ] **M-Pesa Compliance:** Ensure Daraja API calls are logging transaction IDs correctly

---

## Migration Triggers

### When to Upgrade from Sheets to Supabase
- ✅ 50+ traders actively using
- ✅ 500+ orders/week (sheets slow down at this volume)
- ✅ Payment mismatches <5% and stable
- ✅ Chat overload resolved (traders happy with inbox system)
- ✅ You've identified 3+ traders willing to pay for premium features

### Week 4–5 Go/No-Go Decision
Run a quick poll: "Would you pay KSh 200/month for auto-payment matching + daily profit summary?"  
If ≥5 say yes → proceed to Supabase.

---

## Free → Paid Mechanics

### Free Tier
- Catalog sharing + simple order log + payment note field

### Paid Tier (if they hit usage thresholds)
- Auto-M‑Pesa matching and alerts
- WhatsApp shared inbox/agent assignment
- Basic daily profit summaries

---

## 90-Day Pilot → MRR

- **Day 1–30:** Validate flows with 5–20 traders; fix failure modes (missed chats, mismatched payments)
- **Day 31–60:** Introduce light automation (templates, partial matching); onboard 50+ traders
- **Day 61–90:** Start charging modest fees for reconciliation & alerts; measure retention and churn vs manual alternatives

---

## Cost Breakdown (12-Week Pilot)

| Item | Weeks 1–4 | Weeks 5–8 | Weeks 9–12 | Total |
|------|-----------|----------|-----------|-------|
| Meta WhatsApp API | Free | Free | Free | Free |
| Google Sheets | Free | Free | - (migrated) | Free |
| n8n automation | Free | Free | Free | Free |
| M-Pesa Daraja | Free (test) | ~KSh 5/transaction (live) | ~KSh 5–10/transaction | ~KSh 5K–10K |
| Airtable (optional) | $0–20 | - | - | ~KSh 3K–5K |
| Supabase | - | $0–25/mo | $25/mo | ~KSh 7.5K |
| Whalesync (optional) | - | $15–29/mo | $15–29/mo | ~KSh 15K |
| Domain + hosting (optional) | - | - | $5–10/mo | ~KSh 2.5K |
| ERPNext (optional) | - | - | KSh 2K–5K/mo | ~KSh 5K–10K |
| **TOTAL (Budget)** | **Free–5K** | **Free–15K** | **Free–20K** | **~KSh 50K–60K** |

*Note: Costs are minimal because you're a solo dev. Scaling (hiring, support staff) will increase overhead.*

---

## Open Questions & Future Features

**Not in MVP (Weeks 1–12):**
- Credit/partial payments (tracked manually in notes; v2 feature)
- Returns/refunds (handled via chat; formal flow in v2)
- Supplier integration (pricing auto-updates; manual for now)
- Multi-language UI (English only; Swahili templates in broadcasts)
- Offline sync (WiFi assumed; fallback = SMS for critical data)
- Staff roles & permissions (shared access for now; v2 = fine-grained)

**Watch List:**
- Regulatory: Keep eye on eTIMS updates; ERPNext integration eases compliance
- Payment: M-Pesa API changes; Safaricom's newer APIs (e.g., B2C)
- WhatsApp: Meta policy changes on message frequency; stay compliant

---

**Last Updated:** Update this document weekly as you progress through the build.

