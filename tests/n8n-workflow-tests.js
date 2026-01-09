/**
 * n8n Workflow Test Harness
 * Test all v2 workflows with sample data
 * 
 * Architecture: See docs/NATIVE_INTEGRATIONS.md
 * Workflows: See docs/FIRST_7_WORKFLOWS.md
 */

require('dotenv').config();
const axios = require('axios');

const N8N_BASE_URL = process.env.N8N_BASE_URL || 'http://localhost:5678';

/**
 * Test Workflow 1: classify_message_v2
 */
async function testClassifyMessage() {
  console.log('\n=== Test 1: classify_message_v2 ===\n');
  
  const testPayload = {
    message: {
      id: 'test_msg_001',
      from: '+254700456789',
      type: 'text',
      timestamp: Math.floor(Date.now() / 1000),
      text: {
        body: 'I want 2m red chiffon'
      }
    }
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/whatsapp`,
      testPayload,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Classification result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 2: check_consent
 */
async function testCheckConsent() {
  console.log('\n=== Test 2: check_consent ===\n');
  
  const testData = {
    phone: '+254700456789',
    channel: 'whatsapp',
    purpose: 'marketing'
  };
  
  try {
    // Trigger via webhook or direct call
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/check-consent`,
      testData,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Consent check result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 3: send_whatsapp_v2
 */
async function testSendWhatsApp() {
  console.log('\n=== Test 3: send_whatsapp_v2 ===\n');
  
  const testData = {
    phone: '+254700456789',
    message: 'Test message from workflow test',
    message_type: 'transactional',
    session_allowed: true
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/send-whatsapp`,
      testData,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ WhatsApp send result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 4: send_sms_fallback_v2
 */
async function testSendSMSFallback() {
  console.log('\n=== Test 4: send_sms_fallback_v2 ===\n');
  
  const testData = {
    phone: '+254700456789',
    message: 'Test SMS fallback message',
    message_type: 'transactional',
    reason: 'whatsapp_timeout'
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/sms-fallback`,
      testData,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ SMS fallback result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 5: log_message
 */
async function testLogMessage() {
  console.log('\n=== Test 5: log_message ===\n');
  
  const testData = {
    phone: '+254700456789',
    channel: 'whatsapp',
    message_type: 'order_update',
    status: 'delivered',
    message_id: 'test_msg_001',
    cost_kes: 0.75
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/log-message`,
      testData,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Log message result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 6: reconcile_payment_v2
 */
async function testReconcilePayment() {
  console.log('\n=== Test 6: reconcile_payment_v2 ===\n');
  
  const testPayload = {
    Body: {
      stkCallback: {
        MerchantRequestID: 'test_001',
        CheckoutRequestID: 'test_checkout_001',
        ResultCode: 0,
        ResultDesc: 'The service request is processed successfully.',
        CallbackMetadata: {
          Item: [
            { Name: 'Amount', Value: 100000 }, // 1000 KSh in cents
            { Name: 'MpesaReceiptNumber', Value: 'TEST123' },
            { Name: 'PhoneNumber', Value: 254700456789 },
            { Name: 'TransactionDate', Value: 20231219102036 }
          ]
        }
      }
    }
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/mpesa-callback`,
      testPayload,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Payment reconciliation result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Test Workflow 7: send_payment_confirmation_v2
 */
async function testSendPaymentConfirmation() {
  console.log('\n=== Test 7: send_payment_confirmation_v2 ===\n');
  
  const testData = {
    trade_id: 'TR20260109001',
    payment_id: 'PAY20260109001'
  };
  
  try {
    const response = await axios.post(
      `${N8N_BASE_URL}/webhook/payment-confirmation`,
      testData,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Payment confirmation result:', JSON.stringify(response.data, null, 2));
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('🧪 Starting n8n Workflow Tests\n');
  console.log(`n8n Base URL: ${N8N_BASE_URL}\n`);
  
  const results = [];
  
  results.push(await testClassifyMessage());
  results.push(await testCheckConsent());
  results.push(await testSendWhatsApp());
  results.push(await testSendSMSFallback());
  results.push(await testLogMessage());
  results.push(await testReconcilePayment());
  results.push(await testSendPaymentConfirmation());
  
  console.log('\n=== Test Summary ===\n');
  const passed = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  
  console.log(`✅ Passed: ${passed}/${results.length}`);
  console.log(`❌ Failed: ${failed}/${results.length}`);
  
  if (failed > 0) {
    console.log('\n⚠️  Some tests failed. Check n8n workflow execution logs.');
    process.exit(1);
  } else {
    console.log('\n✅ All tests passed!');
    process.exit(0);
  }
}

// Run if called directly
if (require.main === module) {
  runAllTests().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  testClassifyMessage,
  testCheckConsent,
  testSendWhatsApp,
  testSendSMSFallback,
  testLogMessage,
  testReconcilePayment,
  testSendPaymentConfirmation,
  runAllTests
};

