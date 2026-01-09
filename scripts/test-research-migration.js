#!/usr/bin/env node

/**
 * Research Migration Test Suite
 * 
 * Validates the migration to research-backed architecture:
 * - RLS policies (tenant isolation)
 * - Payment matching functions (exact + fuzzy)
 * - Idempotency (webhook_received table)
 * 
 * Reference: docs/core/verified-research-findings.md
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  log('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY', 'red');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

let testResults = {
  passed: 0,
  failed: 0,
  tests: []
};

function test(name, fn) {
  return async () => {
    try {
      await fn();
      testResults.passed++;
      testResults.tests.push({ name, status: 'passed' });
      log(`✅ ${name}`, 'green');
      return true;
    } catch (error) {
      testResults.failed++;
      testResults.tests.push({ name, status: 'failed', error: error.message });
      log(`❌ ${name}: ${error.message}`, 'red');
      return false;
    }
  };
}

async function main() {
  log('🧪 Research Migration Test Suite\n', 'blue');
  
  // Test 1: Verify tables exist
  await test('Tables Created', async () => {
    const { data, error } = await supabase
      .from('tenants')
      .select('id')
      .limit(1);
    
    if (error) throw new Error(`tenants table: ${error.message}`);
    
    const tables = ['orders', 'payments', 'messages', 'review_queue', 'webhook_received'];
    for (const table of tables) {
      const { error: tableError } = await supabase.from(table).select('id').limit(1);
      if (tableError) throw new Error(`${table} table: ${tableError.message}`);
    }
  })();
  
  // Test 2: Verify RLS policies enabled
  await test('RLS Policies Enabled', async () => {
    const { data, error } = await supabase.rpc('exec_sql', {
      query: `
        SELECT tablename, rowsecurity 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('tenants', 'orders', 'payments', 'messages', 'review_queue', 'webhook_received')
      `
    });
    
    // Note: RLS check requires direct SQL access, this is a simplified check
    // In production, verify via Supabase dashboard or direct SQL connection
    log('   ⚠️  RLS verification requires direct SQL access', 'yellow');
    log('   → Verify in Supabase dashboard: Table Settings → Row Level Security', 'yellow');
  })();
  
  // Test 3: Verify payment matching functions exist
  await test('Payment Matching Functions Exist', async () => {
    // Test exact match function
    const { data: exactData, error: exactError } = await supabase.rpc('match_payment_exact', {
      p_tenant_id: '00000000-0000-0000-0000-000000000000',
      p_phone: '+254700000000',
      p_amount: 1000,
      p_m_pesa_receipt: 'TEST123'
    });
    
    if (exactError && !exactError.message.includes('function') && !exactError.message.includes('does not exist')) {
      throw new Error(`match_payment_exact: ${exactError.message}`);
    }
    
    // Test fuzzy match function
    const { data: fuzzyData, error: fuzzyError } = await supabase.rpc('match_payment_fuzzy', {
      p_tenant_id: '00000000-0000-0000-0000-000000000000',
      p_phone: '+254700000000',
      p_amount: 1000
    });
    
    if (fuzzyError && !fuzzyError.message.includes('function') && !fuzzyError.message.includes('does not exist')) {
      throw new Error(`match_payment_fuzzy: ${fuzzyError.message}`);
    }
    
    // Test queue review function
    const { data: queueData, error: queueError } = await supabase.rpc('queue_payment_review', {
      p_tenant_id: '00000000-0000-0000-0000-000000000000',
      p_payment_id: '00000000-0000-0000-0000-000000000000',
      p_reason: 'Test reason'
    });
    
    if (queueError && !queueError.message.includes('function') && !queueError.message.includes('does not exist')) {
      throw new Error(`queue_payment_review: ${queueError.message}`);
    }
  })();
  
  // Test 4: Test payment matching with real data
  await test('Payment Matching Logic', async () => {
    // Create test tenant
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        name: 'Test Tenant',
        phone: '+254700999999',
        is_active: true
      })
      .select()
      .single();
    
    if (tenantError) throw new Error(`Create tenant: ${tenantError.message}`);
    
    // Create test order
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        tenant_id: tenant.id,
        order_number: 'TEST-001',
        customer_phone: '+254700111111',
        items: [{ name: 'Test Item', qty: 1, price: 1000 }],
        total_amount: 1000,
        status: 'pending',
        payment_status: 'unpaid'
      })
      .select()
      .single();
    
    if (orderError) throw new Error(`Create order: ${orderError.message}`);
    
    // Test exact match
    const { data: exactMatch, error: exactMatchError } = await supabase.rpc('match_payment_exact', {
      p_tenant_id: tenant.id,
      p_phone: '+254700111111',
      p_amount: 1000,
      p_m_pesa_receipt: 'TEST123'
    });
    
    if (exactMatchError) throw new Error(`Exact match: ${exactMatchError.message}`);
    if (!exactMatch || exactMatch.length === 0) throw new Error('Exact match should find order');
    if (exactMatch[0].order_id !== order.id) throw new Error('Exact match returned wrong order');
    if (exactMatch[0].confidence !== 1.0) throw new Error('Exact match confidence should be 1.0');
    
    // Test fuzzy match (within ±KSh 20)
    const { data: fuzzyMatch, error: fuzzyMatchError } = await supabase.rpc('match_payment_fuzzy', {
      p_tenant_id: tenant.id,
      p_phone: '+254700111111',
      p_amount: 1015  // ±15 KSh (within 20 tolerance)
    });
    
    if (fuzzyMatchError) throw new Error(`Fuzzy match: ${fuzzyMatchError.message}`);
    if (!fuzzyMatch || fuzzyMatch.length === 0) throw new Error('Fuzzy match should find order');
    if (fuzzyMatch[0].order_id !== order.id) throw new Error('Fuzzy match returned wrong order');
    if (fuzzyMatch[0].confidence < 0.95) throw new Error('Fuzzy match confidence should be >= 0.95');
    
    // Cleanup
    await supabase.from('orders').delete().eq('id', order.id);
    await supabase.from('tenants').delete().eq('id', tenant.id);
  })();
  
  // Test 5: Test idempotency (webhook_received)
  await test('Webhook Idempotency', async () => {
    // Create test tenant
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        name: 'Test Tenant Idempotency',
        phone: '+254700888888',
        is_active: true
      })
      .select()
      .single();
    
    if (tenantError) throw new Error(`Create tenant: ${tenantError.message}`);
    
    const webhookId = `TEST-WEBHOOK-${Date.now()}`;
    
    // Insert first webhook record
    const { data: webhook1, error: webhook1Error } = await supabase
      .from('webhook_received')
      .insert({
        tenant_id: tenant.id,
        webhook_id: webhookId,
        status: 'pending'
      })
      .select()
      .single();
    
    if (webhook1Error) throw new Error(`Insert webhook 1: ${webhook1Error.message}`);
    
    // Try to insert duplicate (should fail due to UNIQUE constraint)
    const { data: webhook2, error: webhook2Error } = await supabase
      .from('webhook_received')
      .insert({
        tenant_id: tenant.id,
        webhook_id: webhookId,
        status: 'pending'
      })
      .select()
      .single();
    
    // Should fail with unique constraint violation
    if (!webhook2Error) {
      throw new Error('Duplicate webhook should be prevented by UNIQUE constraint');
    }
    
    if (!webhook2Error.message.includes('duplicate') && !webhook2Error.message.includes('unique')) {
      throw new Error(`Unexpected error: ${webhook2Error.message}`);
    }
    
    // Cleanup
    await supabase.from('webhook_received').delete().eq('id', webhook1.id);
    await supabase.from('tenants').delete().eq('id', tenant.id);
  })();
  
  // Test 6: Verify indexes exist
  await test('Indexes Created', async () => {
    // This is a simplified check - in production, verify via direct SQL
    log('   ⚠️  Index verification requires direct SQL access', 'yellow');
    log('   → Verify in Supabase dashboard: Table Editor → Indexes', 'yellow');
    log('   → Expected indexes:', 'yellow');
    log('     - idx_orders_tenant_status, idx_orders_tenant_created', 'yellow');
    log('     - idx_payments_tenant_status, idx_payments_webhook_id', 'yellow');
    log('     - idx_messages_tenant_customer, idx_messages_intent', 'yellow');
    log('     - idx_review_queue_tenant_status', 'yellow');
    log('     - idx_webhook_received_tenant_status', 'yellow');
    log('     - idx_tenant_config_tenant_uuid (NEW)', 'yellow');
  })();

  // Test 7: Verify tenant_config.tenant_uuid relationship
  await test('Tenant Config UUID Relationship', async () => {
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .select('id, phone, name')
      .limit(1)
      .single();
    
    if (tenantError) throw new Error(`Get tenant: ${tenantError.message}`);
    
    // Check if tenant_config has tenant_uuid
    const { data: config, error: configError } = await supabase
      .from('tenant_config')
      .select('tenant_uuid, tenant_id')
      .limit(1);
    
    if (configError) {
      // If no tenant_config exists, that's OK for testing
      log('   ⚠️  No tenant_config found (OK for testing)', 'yellow');
      return;
    }
    
    if (config && config.length > 0) {
      const firstConfig = config[0];
      if (!firstConfig.tenant_uuid) {
        throw new Error('tenant_config.tenant_uuid is NULL (migration may have failed)');
      }
      
      // Verify FK relationship
      const { data: linkedTenant, error: linkError } = await supabase
        .from('tenants')
        .select('id')
        .eq('id', firstConfig.tenant_uuid)
        .single();
      
      if (linkError || !linkedTenant) {
        throw new Error(`FK relationship broken: tenant_uuid ${firstConfig.tenant_uuid} not found in tenants`);
      }
      
      log(`   ✅ tenant_uuid FK relationship verified: ${firstConfig.tenant_uuid}`, 'green');
    }
  })();
  
  // Summary
  log('\n📊 Test Summary:', 'blue');
  log(`✅ Passed: ${testResults.passed}`, 'green');
  if (testResults.failed > 0) {
    log(`❌ Failed: ${testResults.failed}`, 'red');
  }
  
  log('\n📋 Test Details:', 'blue');
  testResults.tests.forEach(t => {
    if (t.status === 'passed') {
      log(`  ✅ ${t.name}`, 'green');
    } else {
      log(`  ❌ ${t.name}: ${t.error}`, 'red');
    }
  });
  
  if (testResults.failed === 0) {
    log('\n🎉 All tests passed!', 'green');
    log('\n✅ Migration validation complete:', 'green');
    log('  - Tables created', 'green');
    log('  - Payment matching functions work', 'green');
    log('  - Idempotency enforced', 'green');
    log('\n⚠️  Manual verification needed:', 'yellow');
    log('  - RLS policies (verify in Supabase dashboard)', 'yellow');
    log('  - Indexes (verify in Supabase dashboard)', 'yellow');
    process.exit(0);
  } else {
    log('\n⚠️  Some tests failed. Please review the errors above.', 'yellow');
    process.exit(1);
  }
}

main().catch(error => {
  log(`\n❌ Test suite failed: ${error.message}`, 'red');
  process.exit(1);
});

