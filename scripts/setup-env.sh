#!/bin/bash

# Setup Environment Variables
# Interactive script to help set up .env file

set -e

echo "🔧 Setting up environment variables"
echo "===================================="
echo ""

ENV_FILE="apps/whatsapp-business/.env"
SAMPLE_FILE="apps/whatsapp-business/.sample.env"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
  echo "⚠️  .env file already exists at $ENV_FILE"
  read -p "Do you want to overwrite it? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting. No changes made."
    exit 0
  fi
fi

# Copy sample file
echo "📋 Copying .sample.env to .env..."
cp "$SAMPLE_FILE" "$ENV_FILE"

echo ""
echo "✅ .env file created at $ENV_FILE"
echo ""
echo "📝 Next steps:"
echo "1. Open $ENV_FILE in your editor"
echo "2. Fill in all values marked with 'ADD_..._HERE'"
echo "3. See TOMORROW_ACTION_PLAN.md for where to get each credential"
echo ""
echo "Required credentials:"
echo "  - Supabase: Project URL, Service Role Key, Anon Key"
echo "  - SMSLeopard: API Token, Phone Number ID"
echo "  - SMS Provider: API Key, Sender ID"
echo "  - M-Pesa: Consumer Key, Secret, Shortcode, Passkey"
echo ""

