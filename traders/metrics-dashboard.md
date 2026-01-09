# Metrics Dashboard Setup

## Google Sheets Metrics Dashboard

Create a new sheet called "METRICS" in your main Google Sheet with the following structure:

### Daily Metrics
| Date | Orders | Orders with Payment | Payment Match Rate | Unmatched Payments | Avg Order Value | Total Revenue |
|------|--------|---------------------|-------------------|-------------------|-----------------|---------------|
| 2026-01-20 | =COUNTIF(ORDERS!A:A, ">="&A2) | =COUNTIFS(ORDERS!A:A, ">="&A2, ORDERS!L:L, "Confirmed") | =B2/C2 | =COUNTIFS(DAILY_LOG!B:B, A2, DAILY_LOG!D:D, "Payment Mismatch") | =AVERAGEIF(ORDERS!A:A, ">="&A2, ORDERS!I:I) | =SUMIF(ORDERS!A:A, ">="&A2, ORDERS!I:I) |

### Weekly Summary
| Week | Orders | Payment Match % | Revenue | Automation Success % |
|------|--------|----------------|---------|---------------------|
| Week 1 | =SUMIF(METRICS!A:A, ">="&DATE(2026,1,13), METRICS!B:B) | =AVERAGEIF(METRICS!A:A, ">="&DATE(2026,1,13), METRICS!D:D) | =SUMIF(METRICS!A:A, ">="&DATE(2026,1,13), METRICS!G:G) | =1-(COUNTIF(DAILY_LOG!B:B, ">="&DATE(2026,1,13))/SUMIF(METRICS!A:A, ">="&DATE(2026,1,13), METRICS!B:B)) |

### Automation Health
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Payment Match Rate | >90% | =AVERAGE(METRICS!D:D) | =IF(E2>=0.9, "✅", "⚠️") |
| Chat Overload Incidents | <5% | =COUNTIF(DAILY_LOG!D:D, "Chat Missed")/COUNT(ORDERS!A:A) | =IF(E3<0.05, "✅", "⚠️") |
| Automation Success Rate | >95% | =1-(COUNT(DAILY_LOG!A:A)/COUNT(ORDERS!A:A)) | =IF(E4>=0.95, "✅", "⚠️") |

---

## n8n Automation Monitoring

Add logging nodes to each workflow to track:
- Execution count
- Success/failure rates
- Average execution time
- Error types

### Logging Node Setup
```javascript
// Add to each workflow end node
{
  "operation": "append",
  "sheetName": "AUTOMATION_LOG",
  "columns": {
    "timestamp": "={{new Date().toISOString()}}",
    "workflow": "={{$workflow.name}}",
    "status": "={{$json.status}}",
    "execution_time": "={{$executionTime}}",
    "error": "={{$json.error || ''}}"
  }
}
```

---

## Weekly Review Checklist

Every Friday, review:
- [ ] Payment match rate (target: >90%)
- [ ] Chat overload incidents (target: <5%)
- [ ] Automation success rate (target: >95%)
- [ ] Orders per day trend
- [ ] Revenue per day trend
- [ ] Unmatched payments (manual review)
- [ ] Failed automations (check AUTOMATION_LOG)

---

## Alerts Setup

Create n8n workflow for automated alerts:

**Trigger:** Daily at 6 PM
**Conditions:**
- Payment match rate < 90% → Send alert
- Unmatched payments > 3 → Send alert
- Automation failures > 5 → Send alert

**Action:** Send WhatsApp message to admin/trader via SMSLeopard



