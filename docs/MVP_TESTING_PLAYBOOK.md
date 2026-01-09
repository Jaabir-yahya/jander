# NAIROBI SUPER SUITE: 48-HOUR VALIDATION PLAYBOOK
**For Solo Dev Moving from Build → Test → Iterate**

---

## PART 1: THE 3-WORKFLOW BARE MINIMUM

### What You're Actually Running

**Database (4 migrations only):**
```
1. tenants
2. tenant_config  
3. orders
4. payments
```

**Workflows (3 only):**
```
Workflow 13: Instagram → WhatsApp trigger
Workflow 10: WhatsApp order → Payment
Workflow 06: M-Pesa reconciliation
```

**Everything else: DISABLED** (comment out in n8n, don't delete)

---

## PART 2: THE 48-HOUR DEPLOYMENT BLUEPRINT

### Day 1 - Morning (4 hours): Deploy Bare Minimum

**9:00 AM - Prepare Infrastructure (1 hour)**
```
[ ] Create new n8n project folder: /nairobi-mvp-test
[ ] Copy ONLY migrations 1,2,3,4 to separate file
[ ] Copy ONLY workflows 13, 10, 06
[ ] Create .env file with:
    - SUPABASE_URL (test project)
    - SUPABASE_KEY (test project)
    - N8N_API_KEY
    - INSTAGRAM_ACCESS_TOKEN
    - M_PESA_CONSUMER_KEY
    - M_PESA_CONSUMER_SECRET
[ ] Rename all other workflows to .disabled (don't import)
```

**10:00 AM - Run Migrations (1 hour)**
```sql
-- Run these in order, one at a time
-- 1. Create tenants table
-- 2. Create tenant_config
-- 3. Create orders
-- 4. Create payments
-- Verify: SELECT COUNT(*) FROM tenants; -- should be 0
```

**11:00 AM - Import to n8n (1 hour)**
```
[ ] Login to n8n
[ ] Create credentials:
    - Supabase (test project)
    - Instagram (test account)
    - M-Pesa (sandbox)
[ ] Import Workflow 13 (Instagram trigger)
    - Test: Does it show in list?
[ ] Import Workflow 10 (Order handler)
    - Test: Can you execute it manually?
[ ] Import Workflow 06 (Payment reconciliation)
    - Test: Can you trigger it manually?
[ ] Set all to "Inactive" until Customer 1 ready
```

**12:00 PM - Quick Smoke Test (1 hour)**
```
[ ] Manual test: Execute Workflow 13
    - Expected: No error (Instagram comment data in, error OK if no comment)
[ ] Manual test: Execute Workflow 10
    - Expected: No error (order creation logic works)
[ ] Manual test: Execute Workflow 06
    - Expected: No error (payment matching works)
[ ] Check database:
    - SELECT * FROM orders; -- should be empty
    - SELECT * FROM payments; -- should be empty
```

---

### Day 1 - Afternoon (4 hours): Onboard Customer 1

**1:00 PM - Customer 1 Setup (2 hours)**
```
[ ] Who is Customer 1?
    - Nairobi SME you know (friend/family works)
    - Must have Instagram business account
    - Must have M-Pesa account
    - Available for 2-hour testing today

[ ] Manual Setup (NOT via bot yet):
    - Open Supabase
    - INSERT into tenants: (id, name, status)
    - INSERT into tenant_config: (tenant_id, instagram_token, m_pesa_phone)
    - Give them: WhatsApp link to chat
    
[ ] Brief them (5 minutes):
    - "I'm testing a new tool"
    - "Try posting 'YES' on my Instagram"
    - "You should get WhatsApp message"
    - "Reply with order details"
    - "You should get payment link"
```

**3:00 PM - Watch Them Use It (2 hours)**
```
CRITICAL: Don't help them. Just watch.

[ ] Customer 1 posts Instagram comment
    - Time: ___
    - Comment text: ___
    - Did WhatsApp message arrive? YES / NO / LATE
    
[ ] Customer 1 replies with order
    - Time: ___
    - Order text: ___
    - Did order get created? YES / NO / BROKEN
    - Check database: SELECT * FROM orders WHERE tenant_id='X';
    
[ ] You send payment link manually (if automation broke)
    - Customer 1 sends M-Pesa payment
    - Amount: ___ KSh
    - Receipt: ___
    
[ ] Did payment reconcile automatically?
    - Check: SELECT * FROM payments WHERE tenant_id='X';
    - Did amount match? YES / NO / PARTIAL

[ ] Ask ONE question: "What would make you stop using this tomorrow?"
    - Answer: ___________________________
```

**5:00 PM - Debrief & Fix (ONLY breaking issues)**
```
RULE: Only fix what prevents transactions.

Issues to FIX immediately:
- [ ] Instagram webhook not triggering
- [ ] WhatsApp message not sending
- [ ] Order not creating from WhatsApp text
- [ ] Payment link not sent
- [ ] Payment not matching in database

Issues to IGNORE for now:
- [ ] Message formatting is ugly
- [ ] Slow response time
- [ ] No confirmation animation
- [ ] Database field could be better named
- [ ] Error messages aren't clear
```

---

### Day 2 - Morning (4 hours): Test Reliability & Iterate

**9:00 AM - Review Customer 1 (1 hour)**
```
[ ] Pull overnight logs
[ ] Count: How many complete transactions? ___
[ ] Count: How many failures? ___
[ ] Count: How many manual interventions? ___

Success: ≥1 complete transaction, <2 failures
Failure: 0 complete transactions OR >2 failures (PIVOT immediately)
```

**10:00 AM - Onboard Customer 2 (2 hours)**
```
[ ] Select Customer 2 (different SME type if possible)
[ ] Repeat Day 1 afternoon process
[ ] Watch for 1 complete transaction
[ ] Ask the ONE question
```

**12:00 PM - Fix Only What Breaks (1 hour)**
```
Compare Customer 1 and Customer 2:

Common problem? FIX immediately.
Unique problem to one? IGNORE.

Example:
- Both customers: WhatsApp response slow → FIX
- Only Customer 1: Fonts look bad → IGNORE
```

---

### Day 2 - Afternoon (4 hours): Validation & Decision

**1:00 PM - The Validation Test (2 hours)**
```
Ask Customer 1 and Customer 2:
Q1: "Did this save you time?"
    Customer 1: YES / NO / MAYBE
    Customer 2: YES / NO / MAYBE

Q2: "Would you use this if it worked like this every day?"
    Customer 1: YES / NO / MAYBE
    Customer 2: YES / NO / MAYBE

Q3: "Would you pay KSh 1,499/month?"
    Customer 1: YES / NO / MAYBE
    Customer 2: YES / NO / MAYBE
```

**3:00 PM - Make the Decision**
```
SUCCESS CRITERIA:
- At least 1 customer answered YES to all 3 questions
- At least 2 complete transactions across both customers
- ≤1 major failure that wasn't fixed
- ≥1 clear insight about what they need

IF SUCCESS:
[ ] Onboard Customer 3 (same process)
[ ] Start building from Customer feedback
[ ] Move to PART 3: Market-Driven Build

IF FAILURE:
[ ] Identify blocking issue
[ ] Spend 4 hours fixing it
[ ] Retest with Customer 1
[ ] If still broken: Pivot (different approach needed)
```

---

## PART 3: THE DECISION TREE

### The 3 Possible Outcomes

```
OUTCOME A: ✅ WINS (≥2 YES votes, ≥2 transactions)
├─ Customer 1: YES to all 3 questions
├─ Customer 2: YES to all 3 questions
├─ No blocking issues
└─ NEXT: Onboard Customer 3 → Market-driven build

OUTCOME B: ⚠️  PARTIALLY WORKS (1 YES vote, ≥1 transaction)
├─ Customer 1: YES, Customer 2: MAYBE
├─ 1-2 blocking issues but fixable
├─ Clear pattern of what works
└─ NEXT: Fix blocking issue → Retest → Customer 3

OUTCOME C: ❌ FAILS (0 YES votes OR 0 transactions)
├─ Customers confused about value
├─ System breaking repeatedly
├─ No pattern of what works
└─ NEXT: PIVOT (rethink approach, different SME type, different workflow)
```

---

## PART 4: WHAT TO MEASURE (NOT BUILD)

### The Only Metrics That Matter Right Now

**Operational (Does it work?):**
```
[ ] End-to-end completion rate: ___ %
    (Instagram comment → M-Pesa reconciliation)
    
[ ] Auto-match payment rate: ___ %
    (Payments matched without manual intervention)
    
[ ] Time to complete transaction: ___ minutes
    (Instagram comment to payment confirmed)
    
[ ] Critical failure rate: ___ %
    (Breaks requiring developer intervention)
```

**Market (Would they pay?):**
```
[ ] Customer 1: Would pay KSh 1,499/month?  YES / NO / MAYBE
[ ] Customer 2: Would pay KSh 1,499/month?  YES / NO / MAYBE
[ ] Customer 1: Key pain point: ___________________
[ ] Customer 2: Key pain point: ___________________
```

**That's it. Ignore everything else.**

---

## PART 5: THE "NO New Features" RULE

### What You CAN Do This Week:
```
✅ Fix broken workflows (Customer can't complete transaction)
✅ Improve error handling (Better error messages)
✅ Simplify existing logic (Remove edge cases)
✅ Speed up response (Execution optimization)
✅ Change configuration (Different workflow order)
```

### What You CANNOT Do This Week:
```
❌ Add new tables (inventory, delivery tracking, etc.)
❌ Add new workflows (support triage, analytics, etc.)
❌ Build new features (bulk messaging, VIP tier, etc.)
❌ Improve UI (colors, formatting, animations)
❌ Add edge case handling (partial payments, refunds)
```

---

## PART 6: THE GITHUB CHECKLIST

### Before You Deploy Tomorrow

```markdown
## MVP Deployment Checklist

### Day 1 Morning
- [ ] Rename 21 workflows to .disabled (keep only 3)
- [ ] Prepare 4 migrations (tenants, config, orders, payments)
- [ ] Create minimal .env file
- [ ] Test database connections
- [ ] Test n8n imports (no errors)

### Day 1 Afternoon  
- [ ] Customer 1 completes 1 transaction
- [ ] Zero breaking issues or <1 hour to fix
- [ ] Customer 1 says "This is useful"

### Day 2 Morning
- [ ] Customer 2 completes 1 transaction
- [ ] Pattern emerges (same issues? different?)
- [ ] Fix only common problems

### Day 2 Afternoon
- [ ] ≥2 customers answer YES to "Would you pay KSh 1,499?"
- [ ] ≥2 complete transactions (can be same customer)
- [ ] 1 clear insight about what to build next

### Decision Gate
- [ ] SUCCESS: Move to Customer 3 + Market-Driven Build
- [ ] PARTIAL: Fix blocking issue + Retest
- [ ] FAILURE: Pivot (different approach)
```

---

## PART 7: THE SOLO DEV MINDSET SHIFT

### From Architect to Plumber

**Old Mindset (Over-engineered):**
> "I need to handle 50 tenants, edge cases, emergency failures, analytics"

**New Mindset (Market-validated):**
> "Can 1 customer complete 1 transaction without me debugging?"

**Old Success Metric:**
> "All 24 workflows deployed, 0 errors in logs"

**New Success Metric:**
> "Customer paid KSh X, saved Y minutes, didn't call me confused"

---

## PART 8: EMERGENCY PIVOT SIGNALS

### If You See These, STOP BUILDING & PIVOT

**Signal 1: Customer can't complete transaction**
```
Red flag: After 2 hours, still waiting for payment
Action: Pause everything. Spend 4 hours fixing.
Decision: If still broken after 4 hours, use manual process (you send link)
```

**Signal 2: Same error happens for different customers**
```
Red flag: Customer 1 had payment mismatch, Customer 2 same issue
Action: This is THE bug to fix. Fix now.
Decision: Simplify reconciliation logic if too complex
```

**Signal 3: Customer doesn't understand value**
```
Red flag: "So... it sends WhatsApp? I already use WhatsApp"
Action: Clarify value: "It sends automatically from Instagram leads"
Decision: If still confused, different SME type might understand better
```

**Signal 4: You're explaining too much**
```
Red flag: Customer needs >10 minutes of instructions
Action: Simplify onboarding.
Decision: Use templates or manual setup instead of bot
```

---

## PART 9: THE 48-HOUR TIMELINE

```
DAY 1 (Tomorrow)
├─ 9-12: Deploy bare minimum (3 workflows, 4 tables)
├─ 12-1: Smoke test (manual execution, no errors)
├─ 1-3: Setup Customer 1, brief them
├─ 3-5: Watch them test (Instagram → WhatsApp → Payment)
└─ 5-6: Fix only breaking issues

DAY 2 (Day After)
├─ 9-10: Review overnight, count transactions
├─ 10-12: Onboard Customer 2, repeat test
├─ 12-1: Fix common problems
├─ 1-3: Validation (ask 3 YES/NO questions)
└─ 3-4: Make decision (SUCCESS/PARTIAL/FAILURE)
```

**Total Time: 16 hours across 2 days**

---

## PART 10: POST-VALIDATION (IF YOU WIN)

**If ≥2 customers say YES:**

### Immediately Build (Market-Driven)

**Week 1 (Days 3-7):**
```
What Customer Asked For: ___________________
How to Build It: ___________________
Expected Impact: ___________________

Do NOT build anything they didn't ask for.
```

**Week 2 (Days 8-14):**
```
Customer 1 Pain Point: ___________________
Customer 2 Pain Point: ___________________
Are they the same? YES / NO
Build the one with highest impact.
```

**Week 3 (Days 15-21):**
```
Which workflow fails most? ___________________
Fix it. Deploy. Retest with customers.
```

### Success Metrics for Weeks 2-3:
```
[ ] 3+ customers onboarded (including original 2)
[ ] 95%+ auto-match payment rate
[ ] 95%+ auto-match payment rate
[ ] <5% customer support questions
[ ] ≥1 customer refers another customer
```

---

## THE BOTTOM LINE

**You're not building a product anymore. You're testing a hypothesis:**
> "Can 1 Nairobi SME use this to get orders + payments via WhatsApp in <2 minutes?"

**Tomorrow's success is simple:**
- ✅ Instagram comment → WhatsApp message → M-Pesa payment
- ✅ No developer debugging required
- ✅ Customer says "I'd pay for this"

**Anything else is iteration.**

Now go test.

