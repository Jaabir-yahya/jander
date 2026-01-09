#!/usr/bin/env node

/**
 * Integration Test Script
 * 
 * Tests all integrations with real API calls to verify .env configuration
 * 
 * Usage: node scripts/test-integrations.js
 * 
 * This script will:
 * 1. Test Supabase connection (real query)
 * 2. Test Meta WhatsApp API (verify token works)
 * 3. Test M-Pesa Daraja OAuth (get access token)
 * 4. Test n8n connection (if running)
 * 5. Validate webhook signature setup
 */

// Try to load .env from multiple locations
const path = require('path');
const fs = require('fs');

// Check for .env in current directory or apps/whatsapp-business/
let envPath = process.env.ENV_PATH || '.env';
if (!fs.existsSync(envPath)) {
  const altPath = path.join(__dirname, '..', 'apps', 'whatsapp-business', '.env');
  if (fs.existsSync(altPath)) {
    envPath = altPath;
  }
}

// Require dependencies (NODE_PATH should be set by wrapper script)
const dotenv = require('dotenv');
const axios = require('axios');
const { createClient: supabaseClient } = require('@supabase/supabase-js');

dotenv.config({ path: envPath });
const crypto = require('crypto');

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

function section(title) {
  console.log('\n' + '='.repeat(60));
  log(title, 'cyan');
  console.log('='.repeat(60));
}

const results = {
  passed: [],
  failed: [],
  warnings: []
};

async function testSupabase() {
  section('📊 Testing Supabase Connection');
  
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  if (!url || !key) {
    log('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY', 'red');
    results.failed.push('Supabase: Missing credentials');
    return false;
  }
  
  try {
    log('Connecting to Supabase...', 'blue');
    const supabase = supabaseClient(url, key);
    
    // Test 1: Query tenant_config table
    log('  → Testing database query...', 'blue');
    const { data, error } = await supabase
      .from('tenant_config')
      .select('tenant_id, tenant_name')
      .limit(1);
    
    if (error) {
      log(`❌ Database query failed: ${error.message}`, 'red');
      results.failed.push(`Supabase: ${error.message}`);
      return false;
    }
    
    log(`✅ Supabase connection successful`, 'green');
    log(`   Found ${data?.length || 0} tenant config(s)`, 'green');
    results.passed.push('Supabase: Connection successful');
    return true;
  } catch (error) {
    log(`❌ Supabase test failed: ${error.message}`, 'red');
    results.failed.push(`Supabase: ${error.message}`);
    return false;
  }
}

async function testMetaWhatsApp() {
  section('💬 Testing Meta WhatsApp API');
  
  const token = process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneNumberId = process.env.PHONE_NUMBER_ID;
  const appSecret = process.env.WHATSAPP_APP_SECRET;
  
  if (!token) {
    log('❌ Missing WHATSAPP_ACCESS_TOKEN', 'red');
    results.failed.push('Meta WhatsApp: Missing access token');
    return false;
  }
  
  if (!phoneNumberId) {
    log('❌ Missing PHONE_NUMBER_ID', 'red');
    results.failed.push('Meta WhatsApp: Missing phone number ID');
    return false;
  }
  
  // Test 1: Verify token by fetching phone number info
  try {
    log('  → Testing access token...', 'blue');
    const response = await axios.get(
      `https://graph.facebook.com/v18.0/${phoneNumberId}`,
      {
        headers: {
          'Authorization': `Bearer ${token}`
        },
        params: {
          'fields': 'id,display_phone_number,verified_name'
        },
        timeout: 10000,
        validateStatus: () => true
      }
    );
    
    if (response.status === 200) {
      log('✅ WhatsApp access token is valid', 'green');
      log(`   Phone Number: ${response.data.display_phone_number || phoneNumberId}`, 'green');
      log(`   Verified Name: ${response.data.verified_name || 'N/A'}`, 'green');
      results.passed.push('Meta WhatsApp: Token valid');
    } else if (response.status === 401) {
      log('❌ WhatsApp access token is invalid (401 Unauthorized)', 'red');
      log('   Token may be expired or incorrect', 'red');
      results.failed.push('Meta WhatsApp: Invalid token (401)');
      return false;
    } else {
      log(`⚠️  Unexpected response: ${response.status}`, 'yellow');
      log(`   Response: ${JSON.stringify(response.data)}`, 'yellow');
      results.warnings.push(`Meta WhatsApp: Unexpected status ${response.status}`);
    }
  } catch (error) {
    if (error.response) {
      log(`❌ API call failed: ${error.response.status}`, 'red');
      log(`   ${error.response.data?.error?.message || error.message}`, 'red');
      results.failed.push(`Meta WhatsApp: ${error.response.data?.error?.message || error.message}`);
    } else {
      log(`❌ Network error: ${error.message}`, 'red');
      results.failed.push(`Meta WhatsApp: ${error.message}`);
    }
    return false;
  }
  
  // Test 2: Check webhook signature verification setup
  if (!appSecret) {
    log('⚠️  WHATSAPP_APP_SECRET not set (webhook signature verification disabled)', 'yellow');
    results.warnings.push('Meta WhatsApp: App secret missing (webhook verification disabled)');
  } else {
    log('✅ WHATSAPP_APP_SECRET configured (webhook verification enabled)', 'green');
    results.passed.push('Meta WhatsApp: Webhook signature verification configured');
  }
  
  return true;
}

async function testMPesa() {
  section('💰 Testing M-Pesa Daraja API');
  
  const baseUrl = process.env.DARAJA_BASE_URL || 'https://sandbox.safaricom.co.ke';
  const consumerKey = process.env.DARAJA_CONSUMER_KEY;
  const consumerSecret = process.env.DARAJA_CONSUMER_SECRET;
  const shortcode = process.env.MPESA_SHORTCODE;
  const passkey = process.env.MPESA_PASSKEY;
  
  if (!consumerKey || !consumerSecret) {
    log('❌ Missing DARAJA_CONSUMER_KEY or DARAJA_CONSUMER_SECRET', 'red');
    results.failed.push('M-Pesa: Missing credentials');
    return false;
  }
  
  // Test 1: OAuth token generation
  try {
    log('  → Testing OAuth authentication...', 'blue');
    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
    
    const startTime = Date.now();
    const response = await axios.get(
      `${baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      {
        headers: {
          'Authorization': `Basic ${auth}`
        },
        timeout: 10000,
        validateStatus: () => true
      }
    );
    const responseTime = Date.now() - startTime;
    
    if (response.status === 200 && response.data.access_token) {
      log('✅ M-Pesa OAuth authentication successful', 'green');
      log(`   Environment: ${baseUrl.includes('sandbox') ? 'Sandbox' : 'Production'}`, 'green');
      log(`   Response time: ${responseTime}ms`, 'green');
      log(`   Access token: ${response.data.access_token.substring(0, 20)}...`, 'green');
      results.passed.push('M-Pesa: OAuth authentication successful');
    } else {
      log(`❌ OAuth failed: ${response.status}`, 'red');
      log(`   Response: ${JSON.stringify(response.data)}`, 'red');
      results.failed.push(`M-Pesa: OAuth failed (${response.status})`);
      return false;
    }
  } catch (error) {
    log(`❌ OAuth test failed: ${error.message}`, 'red');
    if (error.response) {
      log(`   Status: ${error.response.status}`, 'red');
      log(`   Data: ${JSON.stringify(error.response.data)}`, 'red');
    }
    results.failed.push(`M-Pesa: ${error.message}`);
    return false;
  }
  
  // Test 2: Check STK Push configuration
  if (!shortcode || !passkey) {
    log('⚠️  MPESA_SHORTCODE or MPESA_PASSKEY not set (STK Push disabled)', 'yellow');
    results.warnings.push('M-Pesa: STK Push not configured');
  } else {
    log('✅ STK Push configured (shortcode and passkey present)', 'green');
    results.passed.push('M-Pesa: STK Push configured');
  }
  
  // Test 3: Check webhook signature verification
  const mpesaSecret = process.env.MPESA_CONSUMER_SECRET;
  if (!mpesaSecret) {
    log('⚠️  MPESA_CONSUMER_SECRET not set (webhook signature verification disabled)', 'yellow');
    results.warnings.push('M-Pesa: Webhook signature verification disabled');
  } else if (mpesaSecret !== consumerSecret) {
    log('⚠️  MPESA_CONSUMER_SECRET differs from DARAJA_CONSUMER_SECRET', 'yellow');
    results.warnings.push('M-Pesa: Consumer secret mismatch');
  } else {
    log('✅ MPESA_CONSUMER_SECRET configured (webhook verification enabled)', 'green');
    results.passed.push('M-Pesa: Webhook signature verification configured');
  }
  
  return true;
}

async function testN8n() {
  section('⚙️  Testing n8n Connection');
  
  const baseUrl = process.env.N8N_BASE_URL || 'http://localhost:5678';
  
  try {
    log(`  → Connecting to ${baseUrl}...`, 'blue');
    const startTime = Date.now();
    const response = await axios.get(`${baseUrl}/healthz`, {
      timeout: 5000,
      validateStatus: () => true
    });
    const responseTime = Date.now() - startTime;
    
    if (response.status === 200) {
      log('✅ n8n is running and healthy', 'green');
      log(`   Response time: ${responseTime}ms`, 'green');
      results.passed.push('n8n: Connection successful');
      return true;
    } else {
      log(`⚠️  n8n returned status ${response.status}`, 'yellow');
      results.warnings.push(`n8n: Status ${response.status}`);
      return false;
    }
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      log('⚠️  n8n is not running (connection refused)', 'yellow');
      log('   Start n8n with: cd apps/n8n && docker-compose up -d', 'yellow');
      results.warnings.push('n8n: Not running (optional for testing)');
    } else if (error.code === 'ETIMEDOUT') {
      log('⚠️  n8n connection timeout', 'yellow');
      results.warnings.push('n8n: Connection timeout');
    } else {
      log(`⚠️  n8n check failed: ${error.message}`, 'yellow');
      results.warnings.push(`n8n: ${error.message}`);
    }
    return false;
  }
}

function testWebhookConfiguration() {
  section('🔐 Testing Webhook Configuration');
  
  const verifyToken = process.env.VERIFY_TOKEN;
  const webhookVerifyToken = process.env.WEBHOOK_VERIFY_TOKEN;
  
  if (!verifyToken) {
    log('❌ Missing VERIFY_TOKEN', 'red');
    results.failed.push('Webhook: Missing VERIFY_TOKEN');
    return false;
  }
  
  if (verifyToken.length < 10) {
    log('⚠️  VERIFY_TOKEN is too short (should be at least 10 characters)', 'yellow');
    results.warnings.push('Webhook: VERIFY_TOKEN too short');
  } else {
    log('✅ VERIFY_TOKEN configured', 'green');
    results.passed.push('Webhook: VERIFY_TOKEN configured');
  }
  
  if (webhookVerifyToken && webhookVerifyToken !== verifyToken) {
    log('⚠️  WEBHOOK_VERIFY_TOKEN differs from VERIFY_TOKEN', 'yellow');
    log('   They should match for consistency', 'yellow');
    results.warnings.push('Webhook: Token mismatch');
  } else if (webhookVerifyToken) {
    log('✅ WEBHOOK_VERIFY_TOKEN matches VERIFY_TOKEN', 'green');
  }
  
  return true;
}

function testEnvironmentVariables() {
  section('📋 Checking Environment Variables');
  
  const required = {
    'SUPABASE_URL': 'Supabase project URL',
    'SUPABASE_SERVICE_ROLE_KEY': 'Supabase service role key',
    'WHATSAPP_ACCESS_TOKEN': 'Meta WhatsApp access token',
    'PHONE_NUMBER_ID': 'Meta WhatsApp phone number ID',
    'VERIFY_TOKEN': 'Webhook verification token',
    'DARAJA_CONSUMER_KEY': 'M-Pesa Daraja consumer key',
    'DARAJA_CONSUMER_SECRET': 'M-Pesa Daraja consumer secret'
  };
  
  const recommended = {
    'WHATSAPP_APP_SECRET': 'Meta WhatsApp app secret (webhook verification)',
    'MPESA_CONSUMER_SECRET': 'M-Pesa consumer secret (webhook verification)',
    'MPESA_SHORTCODE': 'M-Pesa shortcode (STK Push)',
    'MPESA_PASSKEY': 'M-Pesa passkey (STK Push)',
    'NODE_ENV': 'Node environment'
  };
  
  let allRequired = true;
  
  log('\nRequired Variables:', 'blue');
  Object.keys(required).forEach(key => {
    const value = process.env[key];
    if (!value || value.includes('ADD_') || value.includes('your_')) {
      log(`  ❌ ${key}: Missing or placeholder`, 'red');
      results.failed.push(`Env: ${key} missing`);
      allRequired = false;
    } else {
      log(`  ✅ ${key}: Set`, 'green');
    }
  });
  
  log('\nRecommended Variables:', 'blue');
  Object.keys(recommended).forEach(key => {
    const value = process.env[key];
    if (!value || value.includes('ADD_') || value.includes('your_')) {
      log(`  ⚠️  ${key}: ${recommended[key]}`, 'yellow');
      results.warnings.push(`Env: ${key} not set`);
    } else {
      log(`  ✅ ${key}: Set`, 'green');
    }
  });
  
  return allRequired;
}

async function main() {
  console.log('\n');
  log('🧪 Integration Test Suite', 'cyan');
  log('Testing all integrations with real API calls...\n', 'blue');
  
  const startTime = Date.now();
  
  // Run all tests
  const envCheck = testEnvironmentVariables();
  const supabaseTest = await testSupabase();
  const whatsappTest = await testMetaWhatsApp();
  const mpesaTest = await testMPesa();
  const n8nTest = await testN8n();
  const webhookTest = testWebhookConfiguration();
  
  const totalTime = Date.now() - startTime;
  
  // Summary
  section('📊 Test Summary');
  
  log(`\n✅ Passed: ${results.passed.length}`, 'green');
  results.passed.forEach(msg => log(`   • ${msg}`, 'green'));
  
  if (results.warnings.length > 0) {
    log(`\n⚠️  Warnings: ${results.warnings.length}`, 'yellow');
    results.warnings.forEach(msg => log(`   • ${msg}`, 'yellow'));
  }
  
  if (results.failed.length > 0) {
    log(`\n❌ Failed: ${results.failed.length}`, 'red');
    results.failed.forEach(msg => log(`   • ${msg}`, 'red'));
  }
  
  const criticalTests = [envCheck, supabaseTest, whatsappTest, mpesaTest];
  const allCriticalPassed = criticalTests.every(test => test === true);
  
  console.log('\n' + '='.repeat(60));
  if (allCriticalPassed) {
    log('✅ All critical integrations are working!', 'green');
    log(`\n⏱️  Total test time: ${totalTime}ms`, 'blue');
    log('\n🚀 Your .env configuration is complete and working!', 'green');
    process.exit(0);
  } else {
    log('❌ Some critical integrations failed', 'red');
    log('\n⚠️  Please fix the errors above before proceeding', 'yellow');
    process.exit(1);
  }
}

main().catch(error => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});

