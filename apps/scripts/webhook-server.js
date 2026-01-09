/**
 * WhatsApp Webhook Server (SMSLeopard Integration)
 * 
 * Receives webhooks from SMSLeopard WhatsApp Business API
 * Forwards to n8n for processing (automation engine)
 * 
 * Usage: This is optional - n8n can receive webhooks directly from SMSLeopard
 * Use this if you need custom processing before n8n
 */

require('dotenv').config();
const express = require('express');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/whatsapp';

// Middleware
app.use(express.json());

// Verify webhook (SMSLeopard may require verification)
app.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  // Verify token matches your webhook secret
  if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
    console.log('Webhook verified');
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

// Receive WhatsApp messages from SMSLeopard
app.post('/webhook', async (req, res) => {
  try {
    const body = req.body;
    console.log('Received webhook from SMSLeopard:', JSON.stringify(body, null, 2));

    // Forward to n8n for processing
    try {
      await axios.post(N8N_WEBHOOK_URL, body, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      console.log('Forwarded to n8n successfully');
    } catch (error) {
      console.error('Error forwarding to n8n:', error.message);
      // Log error but still return 200 to SMSLeopard
    }

    // Always return 200 to SMSLeopard (webhook received)
    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).send('Error');
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Webhook server running on port ${PORT}`);
  console.log(`Webhook URL: http://localhost:${PORT}/webhook`);
  console.log(`Forwarding to n8n: ${N8N_WEBHOOK_URL}`);
  console.log('Use ngrok to expose: ngrok http', PORT);
});



