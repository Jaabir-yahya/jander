# 🚀 n8n Quick Start

## Docker Setup (Current)

### Start n8n
```bash
cd apps/n8n
docker-compose up -d
```

### Access n8n
Open in browser: **http://localhost:5678**

### View Logs
```bash
docker-compose logs -f
```

### Stop n8n
```bash
docker-compose down
```

---

## 📋 Current Status

✅ **n8n Running:** http://localhost:5678  
✅ **Docker Volume:** `n8n_data` (persistent storage)  
✅ **Timezone:** Africa/Nairobi  
✅ **Runners:** Enabled  

---

## 🔗 Integration with WhatsApp Business API

### Connect n8n Webhooks

1. **Create Webhook in n8n:**
   - Open n8n at http://localhost:5678
   - Create new workflow
   - Add "Webhook" node
   - Set method to POST
   - Activate workflow
   - Copy webhook URL

2. **Expose n8n via ngrok:**
   ```bash
   ngrok http 5678
   ```

3. **Update WhatsApp Webhook:**
   - Use ngrok URL + n8n webhook path
   - Example: `https://abc123.ngrok-free.dev/webhook/whatsapp`
   - Configure in Facebook Console

---

## 📁 Import Workflows

Workflows are stored in `apps/n8n/*.json`:

- `complete-automation-chain.json`
- `media-processing.json`
- `order-processing.json`
- `payment-matching.json`
- `smsleopard-webhook-receiver.json`

**To import:**
1. Open n8n → Workflows → Import from File
2. Select JSON file
3. Configure credentials
4. Activate workflow

---

## 📚 Documentation

- Full setup: [DOCKER_SETUP.md](DOCKER_SETUP.md)
- Workflows: [README.md](README.md)


