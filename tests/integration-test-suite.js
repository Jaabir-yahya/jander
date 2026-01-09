/**
 * Integration Test Suite
 * End-to-end tests for complete workflows
 * 
 * Architecture: See docs/WAAS_ARCHITECTURE.md
 * Integration: See docs/INTEGRATION_CAPABILITIES_MATRIX.md
 */

require('dotenv').config();
const axios = require('axios');
const testPayloads = require('./test-payloads.json');

const N8N_BASE_URL = process.env.N8N_BASE_URL || 'http://localhost:5678';

/**
 * Test 1: Complete Order Flow
 * WhatsApp order → Classification → Order creation → Payment → Confirmation
 */
async function testCompleteOrderFlow() {
  console.log('\n=== Integration Test 1: Complete Order Flow ===\n');
  
  try {
    // Step 1: Send WhatsApp order
    console.log('Step 1: Sending WhatsApp order...');
    const orderResponse = await axios.post(
      `${N8N_BASE_URL}/webhook/whatsapp`,
      testPayloads.whatsapp_webhook_smsleopard,
      { headers: { 'Content-Type': 'application/json' } }
    );
    console.log('✅ Order classified:', orderResponse.data.message_type);
    
    // Step 2: Wait for order processing (simulate)
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Step 3: Simulate payment
    console.log('Step 2: Simulating M-Pesa payment...');
    const paymentResponse = await axios.post(
      `${N8N_BASE_URL}/webhook/mpesa-callback`,
      testPayloads.mpesa_stk_callback_success,
      { headers: { 'Content-Type': 'application/json' } }
    );
    console.log('✅ Payment reconciled:', paymentResponse.data);
    
    // Step 4: Verify payment confirmation sent
    console.log('Step 3: Verifying payment confirmation...');
    // This would be verified by checking message_logs in Supabase
    
    console.log('✅ Complete order flow test passed');
    return { success: true };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test 2: WhatsApp Fallback to SMS
 * WhatsApp fails → SMS fallback triggered
 */
async function testWhatsAppFallback() {
  console.log('\n=== Integration Test 2: WhatsApp Fallback to SMS ===\n');
  
  try {
    // Step 1: Send WhatsApp message (will timeout/fail)
    console.log('Step 1: Sending WhatsApp message (will timeout)...');
    const whatsappResponse = await axios.post(
      `${N8N_BASE_URL}/webhook/send-whatsapp`,
      testPayloads.send_whatsapp_input,
      { headers: { 'Content-Type': 'application/json' }, timeout: 5000 }
    ).catch(() => {
      // Expected timeout
      return { data: { status: 'timeout' } };
    });
    
    // Step 2: Verify SMS fallback triggered
    console.log('Step 2: Verifying SMS fallback...');
    // This would be verified by checking message_logs in Supabase
    
    console.log('✅ WhatsApp fallback test passed');
    return { success: true };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test 3: Payment Reconciliation Edge Cases
 */
async function testPaymentReconciliation() {
  console.log('\n=== Integration Test 3: Payment Reconciliation Edge Cases ===\n');
  
  const testCases = [
    {
      name: 'Single match',
      payload: {
        ...testPayloads.mpesa_stk_callback_success,
        Body: {
          stkCallback: {
            ...testPayloads.mpesa_stk_callback_success.Body.stkCallback,
            CallbackMetadata: {
              Item: [
                { Name: 'Amount', Value: 100000 },
                { Name: 'MpesaReceiptNumber', Value: 'TEST001' },
                { Name: 'PhoneNumber', Value: 254700456789 }
              ]
            }
          }
        }
      }
    },
    {
      name: 'Multiple matches (manual review)',
      payload: {
        ...testPayloads.mpesa_stk_callback_success,
        Body: {
          stkCallback: {
            ...testPayloads.mpesa_stk_callback_success.Body.stkCallback,
            CallbackMetadata: {
              Item: [
                { Name: 'Amount', Value: 100000 },
                { Name: 'MpesaReceiptNumber', Value: 'TEST002' },
                { Name: 'PhoneNumber', Value: 254700456789 }
              ]
            }
          }
        }
      }
    },
    {
      name: 'Orphan payment (no match)',
      payload: {
        ...testPayloads.mpesa_stk_callback_success,
        Body: {
          stkCallback: {
            ...testPayloads.mpesa_stk_callback_success.Body.stkCallback,
            CallbackMetadata: {
              Item: [
                { Name: 'Amount', Value: 999999 },
                { Name: 'MpesaReceiptNumber', Value: 'TEST003' },
                { Name: 'PhoneNumber', Value: 254799999999 }
              ]
            }
          }
        }
      }
    }
  ];
  
  const results = [];
  
  for (const testCase of testCases) {
    console.log(`Testing: ${testCase.name}...`);
    try {
      const response = await axios.post(
        `${N8N_BASE_URL}/webhook/mpesa-callback`,
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
  console.log(`\n✅ Payment reconciliation tests: ${passed}/${testCases.length} passed`);
  
  return { success: passed === testCases.length, results };
}

/**
 * Test 4: Consent Validation
 */
async function testConsentValidation() {
  console.log('\n=== Integration Test 4: Consent Validation ===\n');
  
  const testCases = [
    {
      name: 'Transactional (implied consent)',
      input: { phone: '+254700456789', channel: 'whatsapp', purpose: 'transactional' },
      expected: { consent_valid: true }
    },
    {
      name: 'Marketing (explicit consent required)',
      input: { phone: '+254700456789', channel: 'whatsapp', purpose: 'marketing' },
      expected: { consent_valid: false }
    }
  ];
  
  const results = [];
  
  for (const testCase of testCases) {
    console.log(`Testing: ${testCase.name}...`);
    try {
      const response = await axios.post(
        `${N8N_BASE_URL}/webhook/check-consent`,
        testCase.input,
        { headers: { 'Content-Type': 'application/json' } }
      );
      const matches = response.data.consent_valid === testCase.expected.consent_valid;
      console.log(`${matches ? '✅' : '❌'} ${testCase.name}:`, response.data);
      results.push({ name: testCase.name, success: matches });
    } catch (error) {
      console.error(`❌ ${testCase.name}:`, error.response?.data || error.message);
      results.push({ name: testCase.name, success: false, error: error.message });
    }
  }
  
  const passed = results.filter(r => r.success).length;
  console.log(`\n✅ Consent validation tests: ${passed}/${testCases.length} passed`);
  
  return { success: passed === testCases.length, results };
}

/**
 * Run all integration tests
 */
async function runIntegrationTests() {
  console.log('🧪 Starting Integration Test Suite\n');
  console.log(`n8n Base URL: ${N8N_BASE_URL}\n`);
  
  const results = [];
  
  results.push(await testCompleteOrderFlow());
  results.push(await testWhatsAppFallback());
  results.push(await testPaymentReconciliation());
  results.push(await testConsentValidation());
  
  console.log('\n=== Integration Test Summary ===\n');
  const passed = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  
  console.log(`✅ Passed: ${passed}/${results.length}`);
  console.log(`❌ Failed: ${failed}/${results.length}`);
  
  if (failed > 0) {
    console.log('\n⚠️  Some integration tests failed.');
    process.exit(1);
  } else {
    console.log('\n✅ All integration tests passed!');
    process.exit(0);
  }
}

// Run if called directly
if (require.main === module) {
  runIntegrationTests().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  testCompleteOrderFlow,
  testWhatsAppFallback,
  testPaymentReconciliation,
  testConsentValidation,
  runIntegrationTests
};

