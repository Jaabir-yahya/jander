#!/usr/bin/env node

/**
 * Comprehensive Test Runner
 * 
 * Runs all test suites for the platform
 * Reference: docs/core/WhatsApp_Commerce_Technical_KB.md
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

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

async function runTest(testFile, description) {
  return new Promise((resolve) => {
    log(`\n🧪 ${description}...`, 'cyan');
    
    const testPath = path.join(__dirname, '..', testFile);
    
    if (!fs.existsSync(testPath)) {
      log(`⚠️  Test file not found: ${testFile}`, 'yellow');
      resolve({ success: true, skipped: true });
      return;
    }
    
    const test = spawn('node', [testPath], {
      cwd: path.join(__dirname, '..'),
      stdio: 'inherit'
    });
    
    test.on('close', (code) => {
      if (code === 0) {
        log(`✅ ${description} passed`, 'green');
        resolve({ success: true, skipped: false });
      } else {
        log(`❌ ${description} failed (exit code: ${code})`, 'red');
        resolve({ success: false, skipped: false });
      }
    });
    
    test.on('error', (error) => {
      log(`❌ ${description} error: ${error.message}`, 'red');
      resolve({ success: false, skipped: false });
    });
  });
}

async function main() {
  log('🧪 Comprehensive Test Suite - Nairobi WhatsApp Commerce Platform\n', 'blue');
  
  const tests = [
    {
      file: 'apps/whatsapp-business/scripts/test-order-parser.js',
      description: 'Order Parser Tests'
    },
    {
      file: 'apps/whatsapp-business/scripts/test-trade-facilitator.js',
      description: 'Trade Facilitator Tests'
    },
    {
      file: 'tests/integration-test-suite.js',
      description: 'Integration Tests'
    },
    {
      file: 'tests/n8n-workflow-tests.js',
      description: 'n8n Workflow Tests'
    },
    {
      file: 'tests/test-multi-tenant.js',
      description: 'Multi-Tenant Tests'
    }
  ];
  
  const results = [];
  
  for (const test of tests) {
    const result = await runTest(test.file, test.description);
    results.push({ ...test, ...result });
  }
  
  // Summary
  log('\n📊 Test Summary:', 'blue');
  const passed = results.filter(r => r.success && !r.skipped).length;
  const failed = results.filter(r => !r.success).length;
  const skipped = results.filter(r => r.skipped).length;
  
  log(`✅ Passed: ${passed}`, 'green');
  if (failed > 0) {
    log(`❌ Failed: ${failed}`, 'red');
  }
  if (skipped > 0) {
    log(`⚠️  Skipped: ${skipped}`, 'yellow');
  }
  
  if (failed === 0) {
    log('\n🎉 All tests passed!', 'green');
    process.exit(0);
  } else {
    log('\n⚠️  Some tests failed. Please review the output above.', 'yellow');
    process.exit(1);
  }
}

main().catch(error => {
  log(`\n❌ Test runner failed: ${error.message}`, 'red');
  process.exit(1);
});


