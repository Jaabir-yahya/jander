# Migration Checklist - Native Integrations

**Step-by-step checklist to migrate from custom services to native n8n nodes.**

---

## 📋 Pre-Migration

- [ ] Export all current n8n workflows to JSON (backup)
- [ ] Export `.env` configuration (backup)
- [ ] Create git branch: `git checkout -b native-integrations`
- [ ] Review `docs/NATIVE_INTEGRATIONS.md` strategy
- [ ] Review `docs/REFACTORING_PLAN.md` migration plan

---

## 🔄 Step 1: Create New Workflows (Week 1)

### Workflow 1: classify_message
- [ ] Create `01_classify_message_v2.json` ✅ (Done)
- [ ] Test with sample webhook payload
- [ ] Compare output with v1 workflow
- [ ] Document differences

### Workflow 2: send_whatsapp
- [ ] Create `03_send_whatsapp_v2.json` ✅ (Done)
- [ ] Test session message (within 24h)
- [ ] Test template message (outside 24h)
- [ ] Test delivery receipt handling
- [ ] Test fallback trigger

### Workflow 3: send_sms_fallback
- [ ] Create `04_send_sms_fallback_v2.json` ✅ (Done)
- [ ] Test SMS sending
- [ ] Test message formatting (160 chars)
- [ ] Test logging to Supabase

### Workflow 4: reconcile_payment
- [ ] Create `06_reconcile_payment_v2.json` ✅ (Done)
- [ ] Test payment matching (single match)
- [ ] Test payment matching (multiple matches)
- [ ] Test payment matching (orphan)
- [ ] Test idempotency check

---

## 🧪 Step 2: Testing (Week 2-3)

### Unit Tests
- [ ] Test each workflow independently
- [ ] Test error paths (timeouts, failures)
- [ ] Test edge cases (empty data, null values)
- [ ] Test with invalid credentials

### Integration Tests
- [ ] Test workflow chain: classify → send → log
- [ ] Test payment flow: webhook → match → confirm
- [ ] Test fallback flow: whatsapp fail → sms send
- [ ] Compare outputs with old workflows

### Load Tests
- [ ] Test 100 messages/min
- [ ] Test 1000 messages/min
- [ ] Monitor n8n performance
- [ ] Monitor Supabase performance

---

## 🔀 Step 3: Parallel Run (Week 3-4)

### Setup
- [ ] Deploy v2 workflows alongside v1
- [ ] Configure separate webhook endpoints for v2
- [ ] Set up monitoring/logging for both versions
- [ ] Create comparison dashboard

### Monitoring
- [ ] Monitor v1 workflow executions
- [ ] Monitor v2 workflow executions
- [ ] Compare execution times
- [ ] Compare error rates
- [ ] Compare costs (message costs)

### Validation
- [ ] Compare outputs (v1 vs v2)
- [ ] Check for discrepancies
- [ ] Document any differences
- [ ] Fix any issues found

---

## 🚀 Step 4: Cutover (Week 4)

### Pre-Cutover
- [ ] Final backup of v1 workflows
- [ ] Final backup of database
- [ ] Prepare rollback plan
- [ ] Notify team (if applicable)

### Cutover
- [ ] Disable v1 workflows
- [ ] Enable v2 workflows
- [ ] Update webhook URLs (if needed)
- [ ] Monitor for 24 hours

### Post-Cutover
- [ ] Monitor error rates
- [ ] Monitor execution times
- [ ] Monitor costs
- [ ] Collect user feedback (if applicable)

---

## 🧹 Step 5: Cleanup (Week 4-5)

### Remove Old Services
- [ ] Remove `graph-api-trade-facilitator.js`
- [ ] Remove `erpnext-bridge.js`
- [ ] Remove `mpesa-api.js`
- [ ] Remove `message-logger.js`
- [ ] Remove `payment-reconciler.js`
- [ ] Remove `sms-provider.js`

### Update Code
- [ ] Remove service imports from other files
- [ ] Update `trade-facilitator.js` (remove API calls)
- [ ] Update `app.js` (remove service routes)
- [ ] Update tests (remove service mocks)

### Update Documentation
- [ ] Update `ARCHITECTURE.md`
- [ ] Update `WAAS_ARCHITECTURE.md`
- [ ] Update `INTEGRATION_CAPABILITIES_MATRIX.md`
- [ ] Update `README.md`

### Archive
- [ ] Archive v1 workflows to `apps/n8n/workflows/archive/`
- [ ] Archive old services to `apps/whatsapp-business/services/archive/`
- [ ] Create migration summary document

---

## ✅ Success Criteria

### Code Reduction
- [ ] Removed ~1,200 lines of API wrapper code
- [ ] Kept ~400 lines of business logic
- [ ] Net reduction: 66% less code

### Performance
- [ ] Execution time: Same or better
- [ ] Error rate: Same or better
- [ ] Uptime: 99.9% or better

### Cost
- [ ] Message costs: Same or better
- [ ] Infrastructure costs: Reduced by ~30%

### Maintenance
- [ ] Time to add new provider: <30 minutes
- [ ] Time to update API: <5 minutes
- [ ] Testing time: Reduced by 75%

---

## 📊 Metrics to Track

### Before Migration
- Lines of code (services): ~1,200
- Time to add provider: 2-3 hours
- API update time: 1 hour
- Testing time per workflow: 1 hour
- Production uptime: 95%
- Monthly cost: KSh 15,000

### After Migration
- Lines of code (services): ~400
- Time to add provider: 30 minutes
- API update time: 5 minutes
- Testing time per workflow: 15 minutes
- Production uptime: 99.9%
- Monthly cost: KSh 12,000

---

## 🚨 Rollback Plan

If issues occur during cutover:

1. **Immediate Rollback**:
   - Disable v2 workflows
   - Re-enable v1 workflows
   - Restore webhook URLs
   - Monitor for stability

2. **Investigation**:
   - Review error logs
   - Identify root cause
   - Fix issues in v2 workflows
   - Re-test before re-attempting cutover

3. **Re-Cutover**:
   - Follow cutover steps again
   - Monitor closely
   - Have rollback ready

---

## 📝 Notes

- Keep v1 workflows archived for reference
- Document any differences between v1 and v2
- Update team on migration progress
- Celebrate milestones! 🎉

---

**Last Updated**: 2026-01-09  
**Status**: Migration checklist ready  
**Next**: Start Step 1 (Create new workflows) - Already done! ✅

