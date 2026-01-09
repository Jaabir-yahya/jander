#!/usr/bin/env node

/**
 * Setup Validation Script
 * 
 * Validates that all required components are in place before deployment
 * Reference: docs/guides/WEEK1_ACTION_PLAN.md
 */

const fs = require('fs');
const path = require('path');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function checkFile(filePath, description) {
  const fullPath = path.join(__dirname, '..', filePath);
  if (fs.existsSync(fullPath)) {
    log(`✅ ${description}`, 'green');
    return true;
  } else {
    log(`❌ ${description} - Missing: ${filePath}`, 'red');
    return false;
  }
}

function checkDirectory(dirPath, description) {
  const fullPath = path.join(__dirname, '..', dirPath);
  if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
    const files = fs.readdirSync(fullPath);
    log(`✅ ${description} (${files.length} files)`, 'green');
    return true;
  } else {
    log(`❌ ${description} - Missing: ${dirPath}`, 'red');
    return false;
  }
}

function main() {
  log('🔍 Setup Validation - Nairobi WhatsApp Commerce Platform\n', 'blue');
  
  let allGood = true;
  
  // Core documentation
  log('\n📚 Documentation:', 'blue');
  allGood &= checkFile('docs/00_START_HERE.md', 'Start Here guide');
  allGood &= checkFile('docs/core/PROJECT_MASTER.md', 'Project Master doc');
  allGood &= checkFile('docs/core/WhatsApp_Commerce_Technical_KB.md', 'Technical KB');
  allGood &= checkFile('docs/guides/WEEK1_ACTION_PLAN.md', 'Week 1 Action Plan');
  
  // Database migrations
  log('\n🗄️  Database Migrations:', 'blue');
  allGood &= checkFile('apps/supabase/migrations/001_create_trade_facilitator_schema.sql', 'Trade Facilitator schema');
  allGood &= checkFile('apps/supabase/migrations/002_add_waas_core_tables.sql', 'WaaS core tables');
  allGood &= checkFile('apps/supabase/migrations/003_add_tenant_config.sql', 'Tenant config table');
  
  // n8n workflows
  log('\n⚙️  n8n Workflows:', 'blue');
  allGood &= checkDirectory('apps/n8n/workflows', 'n8n workflows directory');
  allGood &= checkFile('apps/n8n/workflows/00_lookup_tenant_config.json', 'Tenant config lookup');
  allGood &= checkFile('apps/n8n/workflows/01_classify_message_v2.json', 'Message classification');
  allGood &= checkFile('apps/n8n/workflows/03_send_whatsapp_v2.json', 'WhatsApp sending');
  allGood &= checkFile('apps/n8n/workflows/06_reconcile_payment_v2.json', 'Payment reconciliation');
  allGood &= checkFile('apps/n8n/workflows/08_submit_to_etims.json', 'eTIMS submission');
  allGood &= checkFile('apps/n8n/workflows/09_multi_rail_payment.json', 'Multi-rail payments');
  
  // Core services
  log('\n🔧 Core Services:', 'blue');
  allGood &= checkFile('apps/whatsapp-business/services/order-parser.js', 'Order parser');
  allGood &= checkFile('apps/whatsapp-business/services/trade-facilitator.js', 'Trade facilitator');
  allGood &= checkFile('apps/whatsapp-business/services/mpesa-api.js', 'M-Pesa API');
  allGood &= checkFile('apps/whatsapp-business/services/conversation-tracker.js', 'Conversation tracker');
  allGood &= checkFile('apps/whatsapp-business/services/escrow-manager.js', 'Escrow manager');
  
  // Utilities
  log('\n🛠️  Utilities:', 'blue');
  allGood &= checkFile('apps/whatsapp-business/utils/phone-validator.js', 'Phone validator');
  allGood &= checkFile('apps/whatsapp-business/utils/amount-validator.js', 'Amount validator');
  allGood &= checkFile('apps/whatsapp-business/utils/error-handler.js', 'Error handler');
  
  // Scripts
  log('\n📜 Scripts:', 'blue');
  allGood &= checkFile('apps/whatsapp-business/scripts/health-check.js', 'Health check');
  allGood &= checkFile('scripts/test-all.js', 'Test runner');
  allGood &= checkFile('scripts/validate-setup.js', 'Setup validator');
  
  // Configuration
  log('\n⚙️  Configuration:', 'blue');
  allGood &= checkFile('apps/whatsapp-business/.sample.env', 'Environment template');
  allGood &= checkFile('.cursor-rules', 'Cursor rules');
  
  // Tests
  log('\n🧪 Tests:', 'blue');
  allGood &= checkDirectory('tests', 'Tests directory');
  allGood &= checkFile('tests/integration-test-suite.js', 'Integration tests');
  
  // Summary
  log('\n📊 Summary:', 'blue');
  if (allGood) {
    log('✅ All required components are in place!', 'green');
    log('\n🚀 Ready for deployment!', 'green');
    log('\nNext steps:', 'blue');
    log('1. Run: node apps/whatsapp-business/scripts/health-check.js', 'yellow');
    log('2. Follow: docs/guides/WEEK1_ACTION_PLAN.md', 'yellow');
    process.exit(0);
  } else {
    log('❌ Some components are missing. Please review the errors above.', 'red');
    process.exit(1);
  }
}

main();


