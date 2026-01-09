# Scripts

Node.js webhook receivers and utility scripts.

## Files

- `webhook-server.js` - WhatsApp Business Cloud API webhook receiver
- `mpesa-webhook.js` - M-Pesa Daraja C2B webhook processor
- `voice-note-transcriber.js` - Google Speech-to-Text integration
- `sheet-importer.js` - Bulk trader onboarding script

## Setup

1. Install dependencies: `npm install`
2. Configure environment variables (`.env` file)
3. Run locally with ngrok for testing
4. Deploy to production (Vercel/Railway/etc)

## Environment Variables

```
WHATSAPP_ACCESS_TOKEN=...
WHATSAPP_PHONE_NUMBER_ID=...
MPESA_CONSUMER_KEY=...
MPESA_CONSUMER_SECRET=...
GOOGLE_SHEETS_ID=...
GOOGLE_CREDENTIALS=...
```

