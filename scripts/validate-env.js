#!/usr/bin/env node

/**
 * Environment Variables Validation Script
 * 
 * Validates all required environment variables are set and properly formatted
 * Returns exit code 0 if valid, 1 if invalid
 * 
 * Usage: node scripts/validate-env.js [--strict]
 *   --strict: Fail on missing optional variables
 * 
 * Architecture: Week 1 Implementation Plan - Phase 5
 * Date: January 9, 2026
 */

require('dotenv').config();
const logger = require('../apps/whatsapp-business/utils/logger');

const STRICT_MODE = process.argv.includes('--strict');

const REQUIRED_VARS = {
  // Application
  NODE_ENV: { type: 'string', values: ['development', 'staging', 'production'] },
  
  // Supabase (Required)
  SUPABASE_URL: { type: 'url', required: true },
  SUPABASE_SERVICE_ROLE_KEY: { type: 'string', required: true, minLength: 20 },
  
  // WhatsApp (Required)
  WHATSAPP_PROVIDER: { type: 'string', values: ['smsleopard', 'meta'], required: true },
  PHONE_NUMBER_ID: { type: 'string', required: true },
  
  // Webhook (Required)
  VERIFY_TOKEN: { type: 'string', required: true, minLength: 10 },
  
  // M-Pesa (Required)
  DARAJA_CONSUMER_KEY: { type: 'string', required: true },
  DARAJA_CONSUMER_SECRET: { type: 'string', required: true, minLength: 10 },
};

const CONDITIONAL_VARS = {
  // SMSLeopard (required if WHATSAPP_PROVIDER=smsleopard)
  SMSLEOPARD_TOKEN: {
    condition: () => process.env.WHATSAPP_PROVIDER === 'smsleopard',
    type: 'string',
    required: true,
    message: 'Required when WHATSAPP_PROVIDER=smsleopard'
  },
  SMSLEOPARD_WEBHOOK_SECRET: {
    condition: () => process.env.WHATSAPP_PROVIDER === 'smsleopard' && process.env.NODE_ENV === 'production',
    type: 'string',
    required: false,
    message: 'Recommended in production for webhook signature verification'
  },
  
  // Meta (required if WHATSAPP_PROVIDER=meta)
  WHATSAPP_ACCESS_TOKEN: {
    condition: () => process.env.WHATSAPP_PROVIDER === 'meta',
    type: 'string',
    required: true,
    message: 'Required when WHATSAPP_PROVIDER=meta'
  },
  
  // M-Pesa (optional but recommended)
  MPESA_SHORTCODE: {
    condition: () => true,
    type: 'string',
    required: false,
    message: 'Optional but required for STK Push'
  },
  MPESA_PASSKEY: {
    condition: () => true,
    type: 'string',
    required: false,
    message: 'Optional but required for STK Push'
  },
  MPESA_CONSUMER_SECRET: {
    condition: () => true,
    type: 'string',
    required: false,
    message: 'Optional (uses DARAJA_CONSUMER_SECRET if not set)'
  }
};

const OPTIONAL_VARS = {
  SUPABASE_ANON_KEY: { type: 'string' },
  SMS_PROVIDER: { type: 'string', values: ['smsleopard', 'africastalking'] },
  SMSLEOPARD_API_KEY: { type: 'string' },
  AFRICASTALKING_API_KEY: { type: 'string' },
  N8N_BASE_URL: { type: 'url' },
  ERPNEXT_BASE_URL: { type: 'url' },
  LOG_LEVEL: { type: 'string', values: ['debug', 'info', 'warn', 'error'] },
  PORT: { type: 'number', min: 1, max: 65535 },
  REDIS_HOST: { type: 'string' },
  REDIS_PORT: { type: 'number', min: 1, max: 65535 },
  GOOGLE_APPLICATION_CREDENTIALS: { type: 'string' }
};

const errors = [];
const warnings = [];

function validateVar(name, config, value) {
  if (!value && !config.required) {
    return { valid: true, warning: null };
  }
  
  if (!value && config.required) {
    return { valid: false, error: `${name} is required but not set` };
  }
  
  // Type validation
  if (config.type === 'url') {
    try {
      new URL(value);
    } catch (e) {
      return { valid: false, error: `${name} must be a valid URL` };
    }
  }
  
  if (config.type === 'number') {
    const num = parseInt(value, 10);
    if (isNaN(num)) {
      return { valid: false, error: `${name} must be a number` };
    }
    if (config.min !== undefined && num < config.min) {
      return { valid: false, error: `${name} must be >= ${config.min}` };
    }
    if (config.max !== undefined && num > config.max) {
      return { valid: false, error: `${name} must be <= ${config.max}` };
    }
  }
  
  if (config.type === 'string') {
    if (config.minLength && value.length < config.minLength) {
      return { valid: false, error: `${name} must be at least ${config.minLength} characters` };
    }
  }
  
  if (config.values && !config.values.includes(value)) {
    return { valid: false, error: `${name} must be one of: ${config.values.join(', ')}` };
  }
  
  return { valid: true, warning: null };
}

function main() {
  console.log('🔍 Validating Environment Variables...\n');
  
  // Validate required variables
  Object.keys(REQUIRED_VARS).forEach(name => {
    const config = REQUIRED_VARS[name];
    const value = process.env[name];
    const result = validateVar(name, config, value);
    
    if (!result.valid) {
      errors.push(result.error);
      console.error(`❌ ${result.error}`);
    } else {
      console.log(`✅ ${name}`);
    }
  });
  
  // Validate conditional variables
  Object.keys(CONDITIONAL_VARS).forEach(name => {
    const config = CONDITIONAL_VARS[name];
    const value = process.env[name];
    
    if (config.condition()) {
      const result = validateVar(name, config, value);
      
      if (!result.valid) {
        if (config.required) {
          errors.push(result.error);
          console.error(`❌ ${result.error}`);
        } else {
          warnings.push(`${name}: ${config.message}`);
          console.warn(`⚠️  ${name}: ${config.message}`);
        }
      } else {
        console.log(`✅ ${name}`);
      }
    }
  });
  
  // Validate optional variables (if set)
  Object.keys(OPTIONAL_VARS).forEach(name => {
    const value = process.env[name];
    if (value) {
      const config = OPTIONAL_VARS[name];
      const result = validateVar(name, config, value);
      
      if (!result.valid) {
        if (STRICT_MODE) {
          errors.push(result.error);
          console.error(`❌ ${result.error}`);
        } else {
          warnings.push(result.error);
          console.warn(`⚠️  ${result.error}`);
        }
      } else {
        console.log(`✅ ${name} (optional)`);
      }
    }
  });
  
  // Security checks
  console.log('\n🔒 Security Checks...\n');
  
  // Check for development secrets in production
  if (process.env.NODE_ENV === 'production') {
    if (process.env.DARAJA_BASE_URL && process.env.DARAJA_BASE_URL.includes('sandbox')) {
      warnings.push('Using sandbox M-Pesa URL in production');
      console.warn('⚠️  DARAJA_BASE_URL points to sandbox (should be production in production env)');
    }
    
    if (process.env.ALLOW_UNSIGNED_WEBHOOKS === 'true') {
      errors.push('ALLOW_UNSIGNED_WEBHOOKS=true in production (security risk)');
      console.error('❌ ALLOW_UNSIGNED_WEBHOOKS=true in production (security risk)');
    }
    
    if (!process.env.SMSLEOPARD_WEBHOOK_SECRET && process.env.WHATSAPP_PROVIDER === 'smsleopard') {
      warnings.push('SMSLEOPARD_WEBHOOK_SECRET not set in production (webhook signature verification disabled)');
      console.warn('⚠️  SMSLEOPARD_WEBHOOK_SECRET not set (webhook signature verification disabled)');
    }
  }
  
  // Check for placeholder values
  const placeholderPatterns = [
    /ADD_.*_HERE/i,
    /your_.*_here/i,
    /example\.com/i,
    /localhost/i
  ];
  
  Object.keys(REQUIRED_VARS).forEach(name => {
    const value = process.env[name];
    if (value && placeholderPatterns.some(pattern => pattern.test(value))) {
      errors.push(`${name} appears to be a placeholder value`);
      console.error(`❌ ${name} appears to be a placeholder value`);
    }
  });
  
  // Summary
  console.log('\n📊 Summary:\n');
  
  if (errors.length === 0 && (warnings.length === 0 || !STRICT_MODE)) {
    console.log('✅ All required environment variables are valid');
    if (warnings.length > 0) {
      console.log(`\n⚠️  ${warnings.length} warning(s) (non-blocking)`);
    }
    logger.info('Environment validation passed', { errors: errors.length, warnings: warnings.length });
    process.exit(0);
  } else {
    console.error(`❌ ${errors.length} error(s) found`);
    if (warnings.length > 0) {
      console.warn(`⚠️  ${warnings.length} warning(s)`);
    }
    logger.error('Environment validation failed', null, { errors, warnings });
    process.exit(1);
  }
}

main();

