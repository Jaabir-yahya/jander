# n8n Workflows

Exported n8n workflow JSON files for automation.

## 🐳 Docker Setup

n8n is configured to run with Docker for easy deployment.

### Quick Start
```bash
cd apps/n8n

# Start n8n (recommended)
docker-compose up -d

# Or use the run script
./docker-run.sh

# View logs
docker-compose logs -f
```

**Access n8n:** http://localhost:5678

See [DOCKER_SETUP.md](DOCKER_SETUP.md) for complete Docker documentation.

## Workflow Files

### 1. smsleopard-webhook-receiver.json
**Purpose:** Receives WhatsApp messages from SMSLeopard webhook

**Features:**
- Webhook trigger (receives SMSLeopard payload)
- Extracts message data (text, image, audio, sender phone)
- Routes based on message type (text/image/audio)
- Ready for processing nodes

**Setup:**
1. Import this workflow into n8n
2. Activate the workflow
3. Copy webhook URL
4. Configure SMSLeopard dashboard to send webhooks to this URL
5. Test with WhatsApp message

**Next Steps:**
- Connect to order processing workflow
- Add Google Sheets logging
- Add image OCR branch
- Add audio transcription branch

---

## Importing Workflows

1. Open n8n (http://localhost:5678 or cloud.n8n.io)
2. Click "Workflows" → "Import from File"
3. Select JSON file from this folder
4. Review and adjust node configurations
5. Activate workflow

---

## Workflow Structure

```
SMSLeopard Webhook
    ↓
Extract Message Data
    ↓
Route by Type:
├─ Text → Order Parser
├─ Image → OCR Processing
└─ Audio → Transcription
```

---

## Testing

Each workflow should include test data scenarios:
- Happy path: Valid order message
- Error: Invalid format
- Edge: Voice note with low confidence
- Edge: Payment mismatch

---

## Note

These workflows are templates. Customize based on:
- Your SMSLeopard webhook payload structure
- Google Sheets schema
- Order processing logic
- Error handling requirements
