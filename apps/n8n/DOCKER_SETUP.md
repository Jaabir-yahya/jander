# 🐳 Docker Setup for n8n

Complete Docker setup guide for running n8n in the Jander project.

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
cd apps/n8n

# Start n8n
docker-compose up -d

# View logs
docker-compose logs -f

# Stop n8n
docker-compose down
```

### Option 2: Using Docker Run Script

```bash
cd apps/n8n

# Make script executable (first time only)
chmod +x docker-run.sh

# Run n8n
./docker-run.sh
```

### Option 3: Manual Docker Run

```bash
# Create volume (first time only)
docker volume create n8n_data

# Run n8n
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="Africa/Nairobi" \
  -e TZ="Africa/Nairobi" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest
```

## 📋 Configuration

### Environment Variables

- **GENERIC_TIMEZONE**: Set to `Africa/Nairobi` for correct timezone
- **TZ**: System timezone (Africa/Nairobi)
- **N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS**: Security setting
- **N8N_RUNNERS_ENABLED**: Enable workflow runners (for better performance)

### Volumes

- **n8n_data**: Persistent storage for workflows, credentials, and settings
  - Location: Docker volume (managed by Docker)
  - Contains: All n8n data including workflows

### Ports

- **5678**: n8n web interface and API

## 🔍 Management Commands

### Check Status
```bash
# Check if running
docker ps | grep n8n

# Check logs
docker logs n8n

# Or with docker-compose
docker-compose ps
docker-compose logs -f
```

### Stop/Start
```bash
# Stop
docker stop n8n

# Start existing container
docker start n8n

# Remove container (keeps data)
docker rm n8n

# With docker-compose
docker-compose stop
docker-compose start
docker-compose down  # Stops and removes
```

### Access Data
```bash
# View volume info
docker volume inspect n8n_data

# Backup data (example)
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_backup.tar.gz -C /data .

# Restore data (example)
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n_backup.tar.gz -C /data
```

## 🌐 Access

Once running, access n8n at:
- **Local:** http://localhost:5678
- **Network:** http://YOUR_IP:5678

## 🔐 Security (Production)

For production deployment, add these environment variables to `docker-compose.yml`:

```yaml
environment:
  - N8N_BASIC_AUTH_ACTIVE=true
  - N8N_BASIC_AUTH_USER=admin
  - N8N_BASIC_AUTH_PASSWORD=your-secure-password
  - WEBHOOK_URL=https://your-domain.com/
```

## 📊 Integration with WhatsApp Business API

### Webhook Setup

1. Get your n8n webhook URL:
   - Create a webhook node in n8n
   - Copy the webhook URL (e.g., `http://localhost:5678/webhook/whatsapp`)

2. Configure WhatsApp Business API:
   - If using ngrok: `ngrok http 5678`
   - Update Facebook Console webhook URL to ngrok URL + `/webhook/whatsapp`
   - Verify webhook with your verify token

3. Connect workflows:
   - Import workflows from `apps/n8n/*.json`
   - Configure webhook nodes
   - Test with WhatsApp messages

## 🔄 Workflow Import

Import your n8n workflows:

```bash
# Workflows are stored in:
apps/n8n/
├── complete-automation-chain.json
├── media-processing.json
├── order-processing.json
├── payment-matching.json
└── smsleopard-webhook-receiver.json
```

To import:
1. Access n8n at http://localhost:5678
2. Go to Workflows → Import from File
3. Select the JSON file
4. Configure credentials and settings

## 🐛 Troubleshooting

### Issue: Port 5678 already in use
```bash
# Find process using port
lsof -ti:5678

# Kill process or change port in docker-compose.yml
```

### Issue: Volume permission errors
```bash
# Check volume permissions
docker volume inspect n8n_data

# Recreate volume if needed
docker volume rm n8n_data
docker volume create n8n_data
```

### Issue: Container won't start
```bash
# Check logs
docker logs n8n

# Try running without --rm to inspect
docker run -it --name n8n -p 5678:5678 ...
```

### Issue: Can't access n8n
- Check firewall settings
- Verify port mapping: `docker ps` should show `0.0.0.0:5678->5678/tcp`
- Try accessing via `http://127.0.0.1:5678`

## 📚 Additional Resources

- [n8n Docker Documentation](https://docs.n8n.io/hosting/installation/docker/)
- [n8n Documentation](https://docs.n8n.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Last Updated:** 2026-01-09

