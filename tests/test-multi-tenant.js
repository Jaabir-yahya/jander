/**
 * Multi-Tenant Test Suite
 * Test tenant_config lookup and multi-tenant isolation
 * 
 * Architecture: See docs/MULTI_TENANT_GUIDE.md
 */

require('dotenv').config();
const axios = require('axios');

const N8N_BASE_URL = process.env.N8N_BASE_URL || 'http://localhost:5678';
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

/**
 * Test 1: Tenant Config Lookup by ID
 */
async function testTenantLookupById() {
  console.log('\n=== Test 1: Tenant Config Lookup by ID ===\n');
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/lookup-tenant-config`,
      { tenant_id: 'sme_001' },
      { headers: { 'Content-Type': 'application/json' } }
    );
    
    console.log('✅ Tenant config:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test 2: Multi-Rail Payment Routing
 */
async function testMultiRailPayment() {
  console.log('\n=== Test 2: Multi-Rail Payment Routing ===\n');
  
  const testData = {
    tenant_id: 'sme_001',
    order_id: 'ORD001',
    amount: 1000,
    customer_phone: '+254700456789'
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/multi-rail-payment`,
      testData,
      { headers: { 'Content-Type': 'application/json' } }
    );
    
    console.log('✅ Payment rail selected:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test 3: eTIMS Submission
 */
async function testETIMSSubmission() {
  console.log('\n=== Test 3: eTIMS Submission ===\n');
  
  const testData = {
    tenant_id: 'sme_001',
    invoice_id: 'INV001'
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/submit-to-etims`,
      testData,
      { headers: { 'Content-Type': 'application/json' } }
    );
    
    console.log('✅ eTIMS submission:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test 4: Tenant Isolation (Two Tenants)
 */
async function testTenantIsolation() {
  console.log('\n=== Test 4: Tenant Isolation ===\n');
  
  // Test with tenant_id in webhook query param
  const testCases = [
    {
      name: 'Tenant A (sme_001)',
      webhook: `${N8N_BASE_URL}/webhook/whatsapp?tenant_id=sme_001`,
      payload: {
        message: {
          from: '+254700456789',
          text: { body: 'Test message for tenant A' }
        }
      }
    },
    {
      name: 'Tenant B (sme_002)',
      webhook: `${N8N_BASE_URL}/webhook/whatsapp?tenant_id=sme_002`,
      payload: {
        message: {
          from: '+254700456789',
          text: { body: 'Test message for tenant B' }
        }
      }
    }
  ];
  
  const results = [];
  
  for (const testCase of testCases) {
    console.log(`Testing: ${testCase.name}...`);
    try {
      const response = await axios.post(
        testCase.webhook,
        testCase.payload,
        { headers: { 'Content-Type': 'application/json' } }
      );
      
      console.log(`✅ ${testCase.name}:`, response.data);
      results.push({ name: testCase.name, success: true });
    } catch (error) {
      console.error(`❌ ${testCase.name}:`, error.response?.data || error.message);
      results.push({ name: testCase.name, success: false, error: error.message });
    }
  }
  
  const passed = results.filter(r => r.success).length;
  console.log(`\n✅ Tenant isolation tests: ${passed}/${testCases.length} passed`);
  
  return { success: passed === testCases.length, results };
}

/**
 * Test 5: Payment Rails Priority
 */
async function testPaymentRailsPriority() {
  console.log('\n=== Test 5: Payment Rails Priority ===\n');
  
  // Test that highest priority enabled rail is selected
  const testData = {
    tenant_id: 'sme_001',
    order_id: 'ORD001',
    amount: 1000,
    customer_phone: '+254700456789'
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/multi-rail-payment`,
      testData,
      { headers: { 'Content-Type': 'application/json' } }
    );
    
    const railType = response.data.rail_type;
    console.log(`✅ Selected rail: ${railType}`);
    
    // Verify M-Pesa is selected (should be priority 1)
    if (railType === 'mpesa') {
      console.log('✅ Correct: M-Pesa selected (highest priority)');
      return { success: true };
    } else {
      console.log('⚠️  Warning: Expected M-Pesa, got', railType);
      return { success: false, error: 'Wrong rail selected' };
    }
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Run all tests
 */
async function runMultiTenantTests() {
  console.log('🧪 Starting Multi-Tenant Test Suite\n');
  console.log(`n8n Base URL: ${N8N_BASE_URL}\n`);
  
  const results = [];
  
  results.push(await testTenantLookupById());
  results.push(await testMultiRailPayment());
  results.push(await testETIMSSubmission());
  results.push(await testTenantIsolation());
  results.push(await testPaymentRailsPriority());
  
  console.log('\n=== Multi-Tenant Test Summary ===\n');
  const passed = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  
  console.log(`✅ Passed: ${passed}/${results.length}`);
  console.log(`❌ Failed: ${failed}/${results.length}`);
  
  if (failed > 0) {
    console.log('\n⚠️  Some multi-tenant tests failed.');
    process.exit(1);
  } else {
    console.log('\n✅ All multi-tenant tests passed!');
    process.exit(0);
  }
}

// Run if called directly
if (require.main === module) {
  runMultiTenantTests().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  testTenantLookupById,
  testMultiRailPayment,
  testETIMSSubmission,
  testTenantIsolation,
  testPaymentRailsPriority,
  runMultiTenantTests
};

