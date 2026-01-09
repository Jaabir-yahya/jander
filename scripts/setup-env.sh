#!/bin/bash

# Setup Environment Variables Script
# This script helps you create .env file from .sample.env

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WHATSAPP_DIR="$PROJECT_ROOT/apps/whatsapp-business"

echo "🚀 Setting up environment variables..."
echo ""

# Check if .env already exists
if [ -f "$WHATSAPP_DIR/.env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Keeping existing .env file."
        exit 1
    fi
fi

# Check if .sample.env exists
if [ ! -f "$WHATSAPP_DIR/.sample.env" ]; then
    echo "❌ .sample.env file not found at $WHATSAPP_DIR/.sample.env"
    exit 1
fi

# Copy .sample.env to .env
cp "$WHATSAPP_DIR/.sample.env" "$WHATSAPP_DIR/.env"

echo "✅ Created .env file from .sample.env"
echo ""
echo "📝 Next steps:"
echo "1. Open $WHATSAPP_DIR/.env in your editor"
echo "2. Fill in all the values marked with ADD_*_HERE"
echo "3. Generate verify tokens with: openssl rand -hex 32"
echo ""
echo "🔐 Generate verify tokens now? (y/N)"
read -p "> " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Generated tokens (copy these to your .env file):"
    echo "VERIFY_TOKEN=$(openssl rand -hex 32)"
    echo "WEBHOOK_VERIFY_TOKEN=$(openssl rand -hex 32)"
    echo "WEBHOOK_SECRET=$(openssl rand -hex 32)"
    echo ""
fi

echo "✅ Setup complete! Edit $WHATSAPP_DIR/.env to add your credentials."