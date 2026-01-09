#!/bin/bash

# Integration Test Wrapper
# Runs the integration test from the correct directory with dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WHATSAPP_DIR="$PROJECT_ROOT/apps/whatsapp-business"

# Check if we're in the right directory or need to change
if [ -f "$WHATSAPP_DIR/node_modules/dotenv/package.json" ]; then
  # Dependencies are in whatsapp-business
  cd "$WHATSAPP_DIR"
  NODE_PATH="$WHATSAPP_DIR/node_modules:$NODE_PATH" node "$SCRIPT_DIR/test-integrations.js"
elif [ -f "$PROJECT_ROOT/node_modules/dotenv/package.json" ]; then
  # Dependencies are at root
  cd "$PROJECT_ROOT"
  node "$SCRIPT_DIR/test-integrations.js"
else
  echo "❌ Dependencies not found. Please install:"
  echo "   cd apps/whatsapp-business && npm install"
  exit 1
fi

