#!/bin/bash
# Docker run script for n8n with proper configuration

set -e

echo "🐳 Starting n8n with Docker..."
echo ""

# Check if volume exists, create if not
if ! docker volume ls | grep -q n8n_data; then
  echo "📦 Creating Docker volume 'n8n_data'..."
  docker volume create n8n_data
  echo "✅ Volume created"
  echo ""
fi

# Check if container already running
if docker ps | grep -q n8n; then
  echo "⚠️  n8n container is already running"
  echo "   To restart: docker stop n8n && docker rm n8n"
  echo "   Or use: docker-compose down && docker-compose up -d"
  exit 1
fi

echo "🚀 Starting n8n container..."
echo ""
echo "Access n8n at: http://localhost:5678"
echo "Press Ctrl+C to stop"
echo ""

# Run n8n with proper settings
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="Africa/Nairobi" \
  -e TZ="Africa/Nairobi" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest

