/**
 * Health Check Script
 * Check all services and integrations are working
 * 
 * Run: node scripts/health-check.js
 */

require('dotenv').config();
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const checks = [];

/**
 * Check Supabase connection
 */
async function checkSupabase() {
  try {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    
    if (!supabaseUrl || !supabaseKey) {
      return { service: 'Supabase', status: 'skipped', message: 'Credentials not configured' };
    }
    
    const supabase = createClient(supabaseUrl, supabaseKey);
    const { data, error } = await supabase.from('buyers').select('count').limit(1);
    
    if (error) {
      return { service: 'Supabase', status: 'error', message: error.message };
    }
    
    return { service: 'Supabase', status: 'ok', message: 'Connected successfully' };
  } catch (error) {
    return { service: 'Supabase', status: 'error', message: error.message };
  }
}

/**
 * Check n8n is running
 */
async function checkN8N() {
  try {
    const n8nUrl = process.env.N8N_BASE_URL || 'http://localhost:5678';
    const response = await axios.get(`${n8nUrl}/healthz`, { timeout: 5000 });
    
    return { service: 'n8n', status: 'ok', message: 'Running' };
  } catch (error) {
    return { service: 'n8n', status: 'error', message: error.message };
  }
}

/**
 * Check WhatsApp provider configuration
 */
async function checkWhatsApp() {
  const provider = process.env.WHATSAPP_PROVIDER;
  const token = process.env.SMSLEOPARD_TOKEN || process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneNumberId = process.env.PHONE_NUMBER_ID;
  
  if (!provider || !token || !phoneNumberId) {
    return { service: 'WhatsApp', status: 'skipped', message: 'Credentials not configured' };
  }
  
  // Try to verify token (basic check)
  try {
    const apiUrl = provider === 'smsleopard' 
      ? (process.env.SMSLEOPARD_API_BASE_URL || 'https://api.smsleopard.co.ke')
      : 'https://graph.facebook.com/v18.0';
    
    // Just check if credentials are present, don't make actual API call
    return { service: 'WhatsApp', status: 'ok', message: `Provider: ${provider}, Token configured` };
  } catch (error) {
    return { service: 'WhatsApp', status: 'error', message: error.message };
  }
}

/**
 * Check SMS provider configuration
 */
async function checkSMS() {
  const provider = process.env.SMS_PROVIDER;
  const apiKey = process.env.SMSLEOPARD_API_KEY || process.env.AFRICASTALKING_API_KEY;
  const senderId = process.env.SMS_SENDER_ID;
  
  if (!provider || !apiKey || !senderId) {
    return { service: 'SMS', status: 'skipped', message: 'Credentials not configured' };
  }
  
  return { service: 'SMS', status: 'ok', message: `Provider: ${provider}, Sender ID: ${senderId}` };
}

/**
 * Check M-Pesa configuration
 */
async function checkMPesa() {
  const baseUrl = process.env.DARAJA_BASE_URL;
  const consumerKey = process.env.DARAJA_CONSUMER_KEY;
  const consumerSecret = process.env.DARAJA_CONSUMER_SECRET;
  const shortcode = process.env.MPESA_SHORTCODE;
  
  if (!baseUrl || !consumerKey || !consumerSecret || !shortcode) {
    return { service: 'M-Pesa', status: 'skipped', message: 'Credentials not configured' };
  }
  
  return { service: 'M-Pesa', status: 'ok', message: `Base URL: ${baseUrl}, Shortcode: ${shortcode}` };
}

/**
 * Run all health checks
 */
async function runHealthChecks() {
  console.log('🏥 Running Health Checks\n');
  
  checks.push(await checkSupabase());
  checks.push(await checkN8N());
  checks.push(await checkWhatsApp());
  checks.push(await checkSMS());
  checks.push(await checkMPesa());
  
  console.log('Results:\n');
  checks.forEach(check => {
    const icon = check.status === 'ok' ? '✅' : check.status === 'skipped' ? '⏭️' : '❌';
    console.log(`${icon} ${check.service}: ${check.message}`);
  });
  
  const ok = checks.filter(c => c.status === 'ok').length;
  const skipped = checks.filter(c => c.status === 'skipped').length;
  const errors = checks.filter(c => c.status === 'error').length;
  
  console.log(`\nSummary: ${ok} ok, ${skipped} skipped, ${errors} errors`);
  
  if (errors > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runHealthChecks().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = { runHealthChecks, checkSupabase, checkN8N, checkWhatsApp, checkSMS, checkMPesa };

