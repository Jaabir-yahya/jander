# MARKET VALIDATION FRAMEWORK

**Date:** January 9, 2026  
**Status:** Ready for 48-Hour MVP Testing  
**Purpose:** Measure what matters, ignore the rest

---

## THE HYPOTHESIS

> "Can 1 Nairobi SME use this to get orders + payments via WhatsApp in <2 minutes?"

---

## METRICS THAT MATTER

### Operational Metrics (Does it work?)

**1. End-to-End Completion Rate**
```
Formula: (Complete transactions / Total attempts) × 100
Target: ≥80%
Measurement: Instagram comment → M-Pesa reconciliation
```

**2. Auto-Match Payment Rate**
```
Formula: (Auto-matched payments / Total payments) × 100
Target: ≥95%
Measurement: Payments matched without manual intervention
```

**3. Time to Complete Transaction**
```
Formula: Average time from Instagram comment to payment confirmed
Target: <5 minutes
Measurement: Timestamp difference
```

**4. Critical Failure Rate**
```
Formula: (Critical failures / Total transactions) × 100
Target: <5%
Measurement: Breaks requiring developer intervention
```

---

### Market Metrics (Would they pay?)

**1. Time Saved**
```
Question: "Did this save you time?"
Answers: YES / NO / MAYBE
Target: ≥2 YES votes
```

**2. Daily Usage Intent**
```
Question: "Would you use this if it worked like this every day?"
Answers: YES / NO / MAYBE
Target: ≥2 YES votes
```

**3. Willingness to Pay**
```
Question: "Would you pay KSh 1,499/month?"
Answers: YES / NO / MAYBE
Target: ≥2 YES votes
```

**4. Key Pain Points**
```
Question: "What would make you stop using this tomorrow?"
Answers: Free-form text
Target: Identify top 3 pain points
```

---

## VALIDATION CRITERIA

### SUCCESS (Move to Market-Driven Build)
- ✅ ≥2 customers answer YES to all 3 questions
- ✅ ≥2 complete transactions
- ✅ ≤1 major failure (fixed within 4 hours)
- ✅ ≥1 clear insight about what to build next

### PARTIAL (Fix & Retest)
- ⚠️ 1 customer answers YES, 1 answers MAYBE
- ⚠️ 1-2 blocking issues (fixable)
- ⚠️ Clear pattern of what works
- ⚠️ Need to fix blocking issue before Customer 3

### FAILURE (Pivot)
- ❌ 0 customers answer YES
- ❌ 0 complete transactions
- ❌ System breaking repeatedly
- ❌ No clear pattern of what works
- ❌ Need to rethink approach

---

## DATA COLLECTION TEMPLATE

### Customer 1 Test Results

**Date:** _______________
**Time:** _______________

**Transaction 1:**
- Instagram comment time: _______________
- WhatsApp message received: YES / NO / LATE
- Order created: YES / NO / BROKEN
- Payment sent: _______________ KSh
- Payment reconciled: YES / NO / PARTIAL
- Total time: _______________ minutes

**Transaction 2:**
- (Repeat above)

**Validation Questions:**
1. Did this save you time? YES / NO / MAYBE
2. Would you use this daily? YES / NO / MAYBE
3. Would you pay KSh 1,499/month? YES / NO / MAYBE
4. What would make you stop using this? _______________

**Key Insights:**
- What worked well: _______________
- What broke: _______________
- What confused them: _______________

---

### Customer 2 Test Results

**Date:** _______________
**Time:** _______________

(Same template as Customer 1)

---

## DECISION MATRIX

| Metric | Customer 1 | Customer 2 | Decision |
|--------|------------------|------------|----------|
| Time Saved | YES / NO / MAYBE | YES / NO / MAYBE | If ≥2 YES: Build |
| Daily Usage | YES / NO / MAYBE | YES / NO / MAYBE | If ≥2 YES: Build |
| Willing to Pay | YES / NO / MAYBE | YES / NO / MAYBE | If ≥2 YES: Build |
| Complete Transactions | ___ | ___ | If ≥2: Build |
| Common Issues | ___ | ___ | Fix before Customer 3 |

---

## POST-VALIDATION BUILD PRIORITY

### Week 1 (Days 3-7): Customer Request #1
```
What they asked for: ___________________
How to build: ___________________
Expected impact: ___________________
```

### Week 2 (Days 8-14): Customer Request #2
```
What they asked for: ___________________
How to build: ___________________
Expected impact: ___________________
```

### Week 3 (Days 15-21): Fix Most Common Failure
```
Which workflow fails most: ___________________
How to fix: ___________________
Expected impact: ___________________
```

---

## THE GOLDEN RULE

**Build ONLY what customers ask for.**
**Fix ONLY what breaks transactions.**
**Ignore everything else.**

---

**Reference:** `docs/MVP_TESTING_PLAYBOOK.md` for full 48-hour process

