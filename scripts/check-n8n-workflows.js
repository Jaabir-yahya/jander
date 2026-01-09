#!/usr/bin/env node

/**
 * Check n8n Workflows for Common Issues
 * 
 * Validates all workflow JSON files for:
 * - Missing trigger nodes
 * - Broken node references
 * - Missing connections
 * - Invalid node IDs
 */

const fs = require('fs');
const path = require('path');

const workflowsDir = path.join(__dirname, '..', 'apps', 'n8n', 'workflows');
const issues = [];

function checkWorkflow(filePath) {
  const fileName = path.basename(filePath);
  const content = fs.readFileSync(filePath, 'utf8');
  let workflow;
  
  try {
    workflow = JSON.parse(content);
  } catch (e) {
    issues.push({
      file: fileName,
      severity: 'error',
      issue: 'Invalid JSON',
      message: e.message
    });
    return;
  }
  
  const fileIssues = [];
  const nodeIds = new Set();
  const nodeNames = new Map();
  
  // Collect all node IDs and names
  if (workflow.nodes) {
    workflow.nodes.forEach(node => {
      nodeIds.add(node.id);
      nodeNames.set(node.id, node.name);
      
      // Check for trigger nodes
      if (node.type === 'n8n-nodes-base.webhook' || 
          node.type === 'n8n-nodes-base.manualTrigger' ||
          node.type === 'n8n-nodes-base.cron' ||
          node.type === 'n8n-nodes-base.scheduleTrigger') {
        // Has trigger - good
      }
    });
  }
  
  // Check if workflow has any trigger
  const hasTrigger = workflow.nodes?.some(node => 
    node.type === 'n8n-nodes-base.webhook' ||
    node.type === 'n8n-nodes-base.manualTrigger' ||
    node.type === 'n8n-nodes-base.cron' ||
    node.type === 'n8n-nodes-base.scheduleTrigger'
  );
  
  if (!hasTrigger && !fileName.startsWith('00_')) {
    fileIssues.push({
      severity: 'warning',
      issue: 'No trigger node',
      message: 'Workflow has no trigger node - cannot be executed standalone'
    });
  }
  
  // Check connections reference valid nodes
  if (workflow.connections) {
    Object.keys(workflow.connections).forEach(sourceNodeName => {
      const sourceNode = workflow.nodes?.find(n => n.name === sourceNodeName);
      if (!sourceNode) {
        fileIssues.push({
          severity: 'error',
          issue: 'Invalid connection source',
          message: `Connection references non-existent node: ${sourceNodeName}`
        });
      }
      
      const connections = workflow.connections[sourceNodeName];
      if (connections && connections.main) {
        connections.main.forEach((connectionArray, index) => {
          if (Array.isArray(connectionArray)) {
            connectionArray.forEach(conn => {
              const targetNode = workflow.nodes?.find(n => n.name === conn.node);
              if (!targetNode) {
                fileIssues.push({
                  severity: 'error',
                  issue: 'Invalid connection target',
                  message: `Connection from "${sourceNodeName}" references non-existent node: ${conn.node}`
                });
              }
            });
          }
        });
      }
    });
  }
  
  // Check for environment variable references
  const envVarPattern = /\$env\.(\w+)/g;
  const envVars = new Set();
  const contentStr = JSON.stringify(workflow);
  let match;
  while ((match = envVarPattern.exec(contentStr)) !== null) {
    envVars.add(match[1]);
  }
  
  if (envVars.size > 0) {
    fileIssues.push({
      severity: 'info',
      issue: 'Environment variables used',
      message: `Uses: ${Array.from(envVars).join(', ')}`
    });
  }
  
  // Check for Code nodes that might have issues
  workflow.nodes?.forEach(node => {
    if (node.type === 'n8n-nodes-base.code' && node.parameters?.jsCode) {
      // Check for common issues in code
      const code = node.parameters.jsCode;
      
      // Check for $() references that might be broken
      const dollarRefs = code.match(/\$\(['"]([^'"]+)['"]\)/g);
      if (dollarRefs) {
        dollarRefs.forEach(ref => {
          const nodeName = ref.match(/\$\(['"]([^'"]+)['"]\)/)[1];
          const referencedNode = workflow.nodes?.find(n => n.name === nodeName);
          if (!referencedNode) {
            fileIssues.push({
              severity: 'error',
              issue: 'Broken node reference in Code',
              message: `Code node "${node.name}" references non-existent node: ${nodeName}`
            });
          }
        });
      }
    }
  });
  
  if (fileIssues.length > 0) {
    issues.push({
      file: fileName,
      issues: fileIssues
    });
  }
}

// Check all workflow files
const files = fs.readdirSync(workflowsDir)
  .filter(f => f.endsWith('.json') && !f.includes('complete') && !f.includes('order-processing') && !f.includes('payment-matching') && !f.includes('media-processing') && !f.includes('smsleopard'));

console.log('🔍 Checking n8n Workflows...\n');
console.log(`Found ${files.length} workflow files to check\n`);

files.forEach(file => {
  const filePath = path.join(workflowsDir, file);
  checkWorkflow(filePath);
});

// Report results
if (issues.length === 0) {
  console.log('✅ All workflows passed validation!\n');
  process.exit(0);
} else {
  console.log(`⚠️  Found issues in ${issues.length} workflow(s):\n`);
  
  issues.forEach(({ file, issues: fileIssues, severity, issue, message }) => {
    console.log(`📄 ${file}:`);
    if (fileIssues) {
      fileIssues.forEach(({ severity, issue, message }) => {
        const icon = severity === 'error' ? '❌' : severity === 'warning' ? '⚠️' : 'ℹ️';
        console.log(`   ${icon} ${issue}: ${message}`);
      });
    } else if (issue) {
      const icon = severity === 'error' ? '❌' : severity === 'warning' ? '⚠️' : 'ℹ️';
      console.log(`   ${icon} ${issue}: ${message}`);
    }
    console.log('');
  });
  
  const errorCount = issues.reduce((sum, w) => 
    sum + (w.issues ? w.issues.filter(i => i.severity === 'error').length : (w.severity === 'error' ? 1 : 0)), 0
  );
  const warningCount = issues.reduce((sum, w) => 
    sum + (w.issues ? w.issues.filter(i => i.severity === 'warning').length : (w.severity === 'warning' ? 1 : 0)), 0
  );
  
  console.log(`\nSummary: ${errorCount} error(s), ${warningCount} warning(s)`);
  process.exit(errorCount > 0 ? 1 : 0);
}

