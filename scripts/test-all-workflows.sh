#!/bin/bash

# Test All n8n Workflows
# Runs all workflow tests and integration tests

set -e

echo "🧪 Testing All n8n Workflows"
echo "============================"
echo ""

# Check if n8n is running
if ! curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
  echo "⚠️  n8n is not running. Start it with: n8n start"
  echo "   Or set N8N_BASE_URL environment variable"
  exit 1
fi

echo "✅ n8n is running"
echo ""

# Run workflow tests
echo "📋 Running workflow tests..."
cd "$(dirname "$0")/.."
node tests/n8n-workflow-tests.js

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Workflow tests passed"
else
  echo ""
  echo "❌ Workflow tests failed"
  exit 1
fi

# Run integration tests
echo ""
echo "📋 Running integration tests..."
node tests/integration-test-suite.js

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Integration tests passed"
else
  echo ""
  echo "❌ Integration tests failed"
  exit 1
fi

echo ""
echo "✅ All tests passed!"

