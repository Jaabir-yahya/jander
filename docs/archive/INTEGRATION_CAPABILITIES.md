# Integration Capabilities & Requirements

**Maximum capabilities required from each integration for automation, testing, and production readiness.**

This document defines the capabilities each integration must provide to build a reliable, scalable, and testable system. All integrations should support these features for production readiness.

---

## Why SMSLeopard vs Direct Meta Developer Access?

### Current Choice: SMSLeopard

**Why SMSLeopard is currently preferred:**
1. **Regional Availability**: Direct Meta WhatsApp Business Cloud API access is restricted in Kenya (2025-2026)
2. **Meta Partner**: SMSLeopard is an official Meta Business Solution Provider (BSP) with local support
3. **Same API Spec**: Uses Meta's WhatsApp Business API spec - drop-in replacement
4. **Webhook-Native**: Built for automation (not just bulk messaging)
5. **Local Support**: Kenya-based support team for faster resolution
6. **Faster Approval**: Template approval typically faster through BSPs

**When to Use Direct Meta:**
- If Meta direct access becomes available in Kenya
- If you need advanced features only available in direct API
- If cost optimization requires direct API access (lower per-message costs at scale)
- If you're building for global deployment beyond Kenya

**Migration Path**: Architecture supports both - swap provider via environment variable. Same webhook structure, same API patterns.

---

## Integration Capability Requirements

### 1. SMSLeopard / Meta WhatsApp Business API

#### Required Capabilities (Trade Facilitator Specific)

**WhatsApp Flows Support** (Critical for low-literacy UX):
- ✅ Flow creation API (programmatic flow creation)
- ✅ Flow execution tracking (track flow completion)
- ✅ Flow data extraction (get selected values from flow)
- ✅ Flow versioning (test flows before production)
- ✅ Flow templates (reusable flow components)
- ✅ Flow error handling (handle flow failures gracefully)

**Conversation Window Management** (Meta constraint):
- ✅ Track last message timestamp per user
- ✅ Calculate conversation window expiry (24h from last message)
- ✅ Route messages: Session (within 24h) vs Template (outside 24h)
- ✅ Alert users approaching 24h window (keep conversation active)
- ✅ Conversation window expiry handling (switch to templates)

**Dual-User Conversations** (Buyer + Seller):
- ✅ Manage buyer conversation window separately from seller
- ✅ Template routing based on user type (buyer vs seller)
- ✅ Conversation context preservation (link buyer + seller to trade)
- ✅ Multi-user message routing (route to correct user type)

**Quick Replies** (Structured responses):
- ✅ Structured quick replies (CONFIRM, REJECT, YES, NO, READY)
- ✅ Quick reply parsing (map reply to action)
- ✅ Quick reply validation (verify valid reply for context)
- ✅ Quick reply buttons in templates

**Webhook Infrastructure:**
- ✅ Webhook delivery guarantees (at-least-once delivery)
- ✅ Idempotency keys (prevent duplicate processing)
- ✅ Webhook signature verification (HMAC-SHA256)
- ✅ Webhook retry mechanism (exponential backoff, configurable attempts)
- ✅ Webhook batching (process multiple events in one request)

**Message Delivery:**
- ✅ Delivery status webhooks (sent, delivered, read, failed)
- ✅ Message status API (query message status by message_id)
- ✅ Read receipts (when customer reads message)
- ✅ Delivery status tracking (90%+ delivery rate required)

**Rate Limiting & Quotas:**
- ✅ Rate limiting visibility (per-phone-number limits, remaining quota)
- ✅ Quota monitoring API (check remaining quota)
- ✅ Rate limit headers (X-RateLimit-Remaining, X-RateLimit-Reset)
- ✅ Rate limit errors (429 with Retry-After header)

**Templates:**
- ✅ Template approval status API (check approval without dashboard)
- ✅ Template submission API (programmatic template submission)
- ✅ Template versioning (track template versions)
- ✅ Template usage tracking (per template usage count)

**Media & Files:**
- ✅ Media upload API (images, PDFs for invoices)
- ✅ Media download API (download received media)
- ✅ Media expiration handling (handle expired media URLs)
- ✅ File size limits (document size constraints)

**Error Handling:**
- ✅ Detailed error codes (not just HTTP status)
- ✅ Error response schema (structured error messages)
- ✅ Error categorization (rate limit, invalid, server error)
- ✅ Error retry guidance (which errors are retryable)

**Security:**
- ✅ API key authentication
- ✅ Webhook signature verification
- ✅ IP allowlisting (optional)
- ✅ Request signing (HMAC for outbound requests)

**Testing:**
- ✅ Sandbox environment (test without real messages)
- ✅ Test phone numbers (Meta provides test numbers)
- ✅ Webhook verification endpoint (GET with verify_token)
- ✅ Message replay (test webhook delivery)

---

### 2. n8n (Automation Engine)

#### Required Capabilities

**Workflow Execution:**
- ✅ Webhook verification endpoint (GET with verify_token)
- ✅ Workflow versioning (export/import, rollback)
- ✅ Workflow testing mode (dry-run, test data injection)
- ✅ Workflow execution logs (detailed logs per execution)
- ✅ Workflow execution history (view past executions)

**Error Handling:**
- ✅ Error handling nodes (try/catch, retry logic, error branching)
- ✅ Error notification (email, webhook on workflow failure)
- ✅ Error retry configuration (exponential backoff, max attempts)
- ✅ Error aggregation (group similar errors)

**Rate Limiting:**
- ✅ Rate limiting per workflow (prevent API quota exhaustion)
- ✅ Queue nodes (delay execution, rate limiting)
- ✅ Rate limit configuration (per-node, per-workflow)
- ✅ Rate limit monitoring (track rate limit hits)

**Data Transformation:**
- ✅ JSON parsing (parse complex JSON structures)
- ✅ XML parsing (if needed for legacy integrations)
- ✅ CSV parsing (import/export data)
- ✅ Data mapping nodes (transform data structures)
- ✅ Conditional logic (if/else, switch, filters)

**HTTP Integration:**
- ✅ HTTP request nodes (GET, POST, PUT, DELETE, PATCH)
- ✅ Authentication (API key, OAuth, Basic Auth)
- ✅ Custom headers (set request headers)
- ✅ Response handling (status codes, error handling)
- ✅ Request retry (automatic retry on failure)

**Database Integration:**
- ✅ Supabase nodes (CRUD operations)
- ✅ Google Sheets nodes (read/write operations)
- ✅ SQL query nodes (custom SQL execution)
- ✅ Database connection pooling (efficient connections)
- ✅ Transaction support (atomic operations)

**Scheduling:**
- ✅ Cron triggers (schedule workflows)
- ✅ Interval triggers (run every X minutes)
- ✅ Webhook triggers (HTTP webhook receivers)
- ✅ Event triggers (Supabase realtime subscriptions)

**Monitoring:**
- ✅ Workflow execution metrics (success rate, avg duration)
- ✅ Node execution metrics (per-node performance)
- ✅ Error rate monitoring (track error frequency)
- ✅ Workflow health dashboard

---

### 3. Supabase (Database)

#### Required Capabilities

**Data Storage:**
- ✅ Row-Level Security (RLS) policies (traders see only own data)
- ✅ Foreign key constraints (data integrity)
- ✅ Unique constraints (prevent duplicates)
- ✅ Check constraints (validate data ranges)
- ✅ Indexes for performance (on order_id, customer_phone, trader_id)

**Realtime:**
- ✅ Realtime subscriptions (WebSocket triggers)
- ✅ Realtime filters (subscribe to specific rows)
- ✅ Realtime presence (track online users)
- ✅ Realtime channel management (subscribe/unsubscribe)

**Database Operations:**
- ✅ Database migrations (versioned SQL migrations)
- ✅ Database functions (stored procedures)
- ✅ Database triggers (auto-update timestamps, audit logs)
- ✅ Transaction support (atomic operations)
- ✅ Connection pooling (handle concurrent connections)

**Query Performance:**
- ✅ Query performance monitoring (slow query logs)
- ✅ Query plans (EXPLAIN ANALYZE)
- ✅ Index recommendations (suggest missing indexes)
- ✅ Query optimization (optimize slow queries)

**Data Types:**
- ✅ JSONB columns (flexible metadata storage)
- ✅ Full-text search (for product search)
- ✅ Array types (store lists)
- ✅ Timestamp types (with timezone support)

**Backup & Recovery:**
- ✅ Automated daily backups (point-in-time recovery)
- ✅ Database replication (high availability)
- ✅ Backup restoration (restore from backups)
- ✅ Backup retention (keep backups for X days)

**Security:**
- ✅ API rate limiting (prevent abuse)
- ✅ API key management (rotate keys)
- ✅ SSL/TLS encryption (secure connections)
- ✅ Row-Level Security enforcement (verified)

**Monitoring:**
- ✅ Database metrics (CPU, memory, disk usage)
- ✅ Connection metrics (active connections, pool usage)
- ✅ Query metrics (slow queries, query frequency)
- ✅ Storage metrics (database size, growth rate)

---

### 4. M-Pesa Daraja API

#### Required Capabilities

**STK Push:**
- ✅ STK Push API (initiate payment request)
- ✅ STK Push callback webhook (payment confirmation)
- ✅ STK Push status query (check payment status)
- ✅ STK Push timeout handling (handle expired pushes)
- ✅ STK Push retry logic (retry failed pushes)

**Transaction Management:**
- ✅ Query transaction status API (check payment by receipt number)
- ✅ Transaction reversal API (refund capability)
- ✅ Transaction history API (list transactions)
- ✅ Transaction search (search by phone, date, amount)

**Webhooks:**
- ✅ Webhook signature verification (validate callback authenticity)
- ✅ Webhook retry mechanism (Daraja retries failed webhooks)
- ✅ Webhook timeout handling (handle slow webhooks)
- ✅ Webhook batching (multiple transactions in one callback)

**Security:**
- ✅ OAuth authentication (secure API access)
- ✅ Access token refresh (auto-refresh tokens)
- ✅ API key management (rotate keys)
- ✅ IP allowlisting (restrict API access)

**Error Handling:**
- ✅ Detailed error codes (not just HTTP status)
- ✅ Error response schema (structured error messages)
- ✅ Error retry guidance (which errors are retryable)
- ✅ Error logging (log all API errors)

**Testing:**
- ✅ Sandbox environment (test without real transactions)
- ✅ Test credentials (sandbox API keys)
- ✅ Test phone numbers (sandbox test numbers)
- ✅ Webhook simulation (simulate webhook callbacks)

**Monitoring:**
- ✅ Account balance API (check till/paybill balance)
- ✅ Transaction volume API (track transaction volume)
- ✅ Rate limit visibility (remaining API quota)
- ✅ Transaction analytics (transaction trends)

---

### 5. Google Cloud Speech-to-Text

#### Required Capabilities

**Transcription:**
- ✅ Multiple language support (sw-KE, en-KE, so-KE)
- ✅ Auto-detect language (for Sheng/mixed languages)
- ✅ Confidence scores (flag low-confidence transcriptions)
- ✅ Word timestamps (timestamps per word)
- ✅ Speaker diarization (identify multiple speakers)

**Audio Processing:**
- ✅ Audio format conversion (OGG, AMR to WAV)
- ✅ Audio format detection (auto-detect format)
- ✅ Audio preprocessing (noise reduction, normalization)
- ✅ File size limits (handle large audio files)

**Batch Processing:**
- ✅ Batch transcription (process multiple audio files)
- ✅ Streaming transcription (real-time transcription)
- ✅ Async transcription (submit job, poll for results)
- ✅ Transcription status API (check job status)

**Error Handling:**
- ✅ Timeout handling (handle long audio files)
- ✅ File size limits (reject oversized files)
- ✅ Format errors (handle unsupported formats)
- ✅ Error retry (retry transient errors)

**Rate Limiting:**
- ✅ Rate limiting visibility (per-project quotas)
- ✅ Quota monitoring (check remaining quota)
- ✅ Rate limit errors (429 with Retry-After)
- ✅ Quota increase requests (request higher quotas)

**Cost Tracking:**
- ✅ Cost monitoring (track API usage costs)
- ✅ Cost alerts (alert on high usage)
- ✅ Budget limits (set spending limits)
- ✅ Usage reports (detailed usage breakdown)

---

### 6. Google Cloud Vision API (OCR)

#### Required Capabilities

**Text Detection:**
- ✅ Text detection (OCR from images)
- ✅ Handwritten text recognition (for order notes)
- ✅ Multiple language support (English, Swahili)
- ✅ Confidence scores (flag low-confidence extractions)
- ✅ Text localization (bounding boxes for text)

**Image Processing:**
- ✅ Image format support (JPG, PNG, PDF)
- ✅ Image preprocessing (orientation detection, noise reduction)
- ✅ Image quality detection (flag low-quality images)
- ✅ File size limits (handle large images)

**Batch Processing:**
- ✅ Batch processing (process multiple images)
- ✅ Async processing (submit job, poll for results)
- ✅ Processing status API (check job status)
- ✅ Batch results export (export all results)

**Error Handling:**
- ✅ Timeout handling (handle large images)
- ✅ File size limits (reject oversized files)
- ✅ Format errors (handle unsupported formats)
- ✅ Error retry (retry transient errors)

**Rate Limiting:**
- ✅ Rate limiting visibility (per-project quotas)
- ✅ Quota monitoring (check remaining quota)
- ✅ Rate limit errors (429 with Retry-After)
- ✅ Quota increase requests (request higher quotas)

**Cost Tracking:**
- ✅ Cost monitoring (track API usage costs)
- ✅ Cost alerts (alert on high usage)
- ✅ Budget limits (set spending limits)
- ✅ Usage reports (detailed usage breakdown)

---

### 7. M-Pesa B2C Payout API (For Seller Payouts)

#### Required Capabilities (Trade Facilitator Specific)

**B2C Payout:**
- ✅ Initiate B2C payout API (send payment to seller)
- ✅ B2C payout callback webhook (payout confirmation)
- ✅ Payout status query API (check payout status)
- ✅ Payout failure handling (handle failed payouts)
- ✅ Payout retry logic (retry failed payouts)

**Security:**
- ✅ Payout signature verification (validate callback authenticity)
- ✅ Idempotency keys (prevent duplicate payouts)
- ✅ Payout limits (daily/monthly payout limits)

**Testing:**
- ✅ Sandbox payout testing (test without real transactions)
- ✅ Payout webhook simulation (simulate payout callbacks)

---

### 8. ERPNext (Optional - Week 9+)

#### Required Capabilities

**REST API:**
- ✅ REST API (create Sales Orders, Invoices)
- ✅ API authentication (API key, token-based)
- ✅ API versioning (support multiple API versions)
- ✅ API rate limiting (prevent abuse)
- ✅ API documentation (OpenAPI/Swagger spec)

**Core Operations:**
- ✅ Create Sales Order (from WhatsApp order)
- ✅ Generate Invoice (eTIMS-ready)
- ✅ Create Customer (auto-create from phone)
- ✅ Update Stock (deduct stock on order)
- ✅ Product matching API (fuzzy search for products)

**eTIMS Integration:**
- ✅ eTIMS invoice generation (KRA compliance)
- ✅ eTIMS invoice submission (submit to KRA)
- ✅ eTIMS invoice status (check submission status)
- ✅ eTIMS invoice retrieval (download invoices)

**Webhooks:**
- ✅ Webhook support (trigger workflows on ERPNext events)
- ✅ Webhook signature verification (validate webhooks)
- ✅ Webhook retry mechanism (retry failed webhooks)
- ✅ Webhook filtering (subscribe to specific events)

**Error Handling:**
- ✅ Detailed error messages (structured errors)
- ✅ Error codes (categorized errors)
- ✅ Error retry guidance (which errors are retryable)
- ✅ Error logging (log all API errors)

**Testing:**
- ✅ Sandbox environment (test without real data)
- ✅ Test data setup (seed test data)
- ✅ API testing tools (Postman collection)
- ✅ Integration testing (test full workflow)

---

## Critical Missing Capabilities (High Priority)

These capabilities are missing from current architecture but are critical for production:

### 1. Webhook Verification & Security
- **Status**: ❌ Not implemented
- **Priority**: Critical
- **Impact**: Vulnerable to replay attacks, unauthorized access
- **Implementation**: Add HMAC signature verification for all webhooks

### 2. Idempotency Keys
- **Status**: ❌ Not implemented
- **Priority**: Critical
- **Impact**: Duplicate orders, duplicate payments processed
- **Implementation**: Add idempotency keys to all external API calls

### 3. Error Handling & Retry
- **Status**: ⚠️ Partial (basic error handling exists)
- **Priority**: Critical
- **Impact**: Single API failure breaks entire workflow
- **Implementation**: Add comprehensive error handling with exponential backoff

### 4. Rate Limiting & Throttling
- **Status**: ❌ Not implemented
- **Priority**: Critical
- **Impact**: API quota exhaustion, account suspension
- **Implementation**: Add rate limiting per trader, per workflow

### 5. Monitoring & Alerting
- **Status**: ❌ Not implemented
- **Priority**: Critical
- **Impact**: Silent failures, no visibility into production issues
- **Implementation**: Add system health monitoring, failure alerts

### 6. Test Data Factories
- **Status**: ❌ Not implemented
- **Priority**: High
- **Impact**: Manual testing is slow, error-prone
- **Implementation**: Add automated test data generation

### 7. Environment Management
- **Status**: ⚠️ Partial (.env files exist)
- **Priority**: High
- **Impact**: Testing breaks production, data leaks
- **Implementation**: Add separate dev/staging/prod environments

### 8. Logging & Observability
- **Status**: ⚠️ Partial (basic logging exists)
- **Priority**: High
- **Impact**: Debugging is slow, no audit trail
- **Implementation**: Add structured logging, request tracing

### 9. Backup & Disaster Recovery
- **Status**: ❌ Not implemented
- **Priority**: High
- **Impact**: Data loss, business continuity issues
- **Implementation**: Add automated database backups, recovery procedures

### 10. Multi-Tenancy Isolation
- **Status**: ⚠️ Partial (RLS planned but not verified)
- **Priority**: High
- **Impact**: Traders see each other's data, GDPR violations
- **Implementation**: Verify Row-Level Security (RLS) policies

---

## Implementation Priority by Stage

### Stage 1 (Weeks 1-2) - Foundation
1. Webhook verification (HMAC signatures)
2. Idempotency keys (all external API calls)
3. Error handling with retry (exponential backoff)
4. Basic logging (structured logs)
5. Environment management (.env files, separate configs)

### Stage 2 (Weeks 3-4) - Containment
6. Rate limiting (per trader, per workflow)
7. Message queuing (failed webhook queue)
8. Health check endpoints
9. Test data factories
10. Monitoring dashboard (basic)

### Stage 3 (Weeks 5-8) - Integration
11. Database migrations (versioned)
12. Backup and disaster recovery (automated)
13. Multi-tenancy isolation (RLS verification)
14. Circuit breakers (external APIs)
15. Webhook replay mechanism

### Stage 4 (Weeks 9-12) - Maturity
16. Feature flags
17. Comprehensive analytics (event tracking)
18. Customer support integration
19. Secrets management (proper storage)
20. API versioning

---

## Testing Requirements

Each integration must be tested for:
- ✅ Happy path (successful operations)
- ✅ Error handling (API failures, timeouts)
- ✅ Rate limiting (quota exhaustion)
- ✅ Retry logic (transient failures)
- ✅ Security (authentication, authorization)
- ✅ Performance (response times, throughput)
- ✅ Idempotency (duplicate request handling)
- ✅ Webhook delivery (delivery guarantees)

See [`INTEGRATION_TESTS.md`](../tests/INTEGRATION_TESTS.md) for detailed test cases.

---

## Trade Facilitator Model

**For hub-and-spoke architecture (single WABA orchestrating buyer-seller trades), see:**
- [`TRADE_FACILITATOR_ARCHITECTURE.md`](./architecture/TRADE_FACILITATOR_ARCHITECTURE.md) - Complete Trade Facilitator architecture

**Core Model:**
- Single WABA as hub (all conversations through your business number)
- Buyers connect via personal WhatsApp (use WhatsApp Flows for low-literacy UX)
- Sellers connect via personal WhatsApp (receive templated notifications)
- Platform orchestrates flows, payments, and notifications

**Data Model:**
- `trades` - Central entity (buyer, seller, product, amount, status)
- `buyers` - Buyer profiles (phone, name, delivery area, conversation window)
- `sellers` - Seller profiles (phone, business, till number, conversation window)
- `products` - Seller catalog (name, price, image, category)
- `conversations` - Track 24h conversation windows per user
- `payments` - Payment transactions (STK push, receipt, status)
- `payouts` - Seller payouts (B2C payout, receipt, status)

**Workflow:**
1. Discovery → Intent (Buyer browses catalog via WhatsApp Flow)
2. Order → Seller Notification (Template: "Buyer wants X, reply CONFIRM/REJECT")
3. Confirmation → Payment (STK push to buyer, payment webhook)
4. Dispatch → Delivery (Seller marks ready, buyer confirms delivery)
5. Delivery → Payout (M-Pesa B2C payout to seller after delivery confirmation)

**Cost Model:**
- **Per Trade Cost**: KSh 1.88 (conversations: 2.5 × KSh 0.75) + KSh 0.50 (platform) = **KSh 2.38 total cost**
- **Transaction Fee**: KSh 50–100 per successful trade (2.5–5% of average KSh 2,000 order)
- **Net Margin**: KSh 47.62–97.62 per trade
- **Break-Even**: ~50–105 trades/month (depending on transaction fee)

**Constraints:**
- Unverified WABA: 250 conversations/day (~125 trades/day max)
- Verified WABA: 1,000–2,000+ conversations/day (~500–1,000 trades/day)
- Template requirement: Messages outside 24h window must use templates
- Low-literacy UX: WhatsApp Flows for structured interactions (no free text)

**Trade Facilitator Specific Capabilities:**
- WhatsApp Flows (product catalog, quantity selector, delivery area selector)
- Conversation window management (24h window tracking per user)
- Dual-user conversations (buyer + seller separate windows)
- Quick replies (CONFIRM, REJECT, YES, NO, READY)
- Escrow logic (hold payment until delivery confirmation)
- M-Pesa B2C payouts (release payment to seller after delivery)

---

## References

- **Architecture**: [`ARCHITECTURE.md`](./core/ARCHITECTURE.md) - System design
- **Trade Facilitator**: [`TRADE_FACILITATOR_ARCHITECTURE.md`](./architecture/TRADE_FACILITATOR_ARCHITECTURE.md) - Hub-and-spoke model
- **Communication Rails**: See [`COMMUNICATION_RAILS.md`](./COMMUNICATION_RAILS.md) for API contracts (if exists)
- **Analytics**: [`ANALYTICS_SCHEMA.md`](./ANALYTICS_SCHEMA.md) - Metrics tracking
- **Test Scenarios**: [`../tests/test-scenarios.md`](../tests/test-scenarios.md) - Week 1 tests
- **Integration Tests**: [`../tests/INTEGRATION_TESTS.md`](../tests/INTEGRATION_TESTS.md) - Comprehensive test cases

---

**Last Updated**: 2026-01-09  
**Status**: Stage 1 capabilities defined, implementation in progress  
**Next Review**: End of Week 1 (capability verification)

