/**
 * M-Pesa Daraja C2B Webhook Processor
 * 
 * Receives payment callbacks from M-Pesa Daraja API
 * Matches payments to orders in Google Sheets
 * Updates payment status automatically
 */

require('dotenv').config();
const express = require('express');
const axios = require('axios');
const { google } = require('googleapis');

const app = express();
const PORT = process.env.PORT || 3001;
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/mpesa';

app.use(express.json());

/**
 * M-Pesa Daraja webhook endpoint
 * Receives C2B payment confirmation callbacks
 */
app.post('/webhook/mpesa', async (req, res) => {
  try {
    const body = req.body;
    console.log('Received M-Pesa webhook:', JSON.stringify(body, null, 2));

    // Extract payment details from Daraja payload
    const paymentData = extractPaymentData(body);

    if (!paymentData) {
      console.error('Invalid payment data received');
      return res.status(400).send('Invalid payment data');
    }

    // Forward to n8n for automated matching
    try {
      await axios.post(N8N_WEBHOOK_URL, {
        eventType: 'mpesa_payment',
        ...paymentData
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      console.log('Forwarded payment to n8n for matching');
    } catch (error) {
      console.error('Error forwarding to n8n:', error.message);
      // Log error but continue processing
    }

    // Always return success to M-Pesa (webhook received)
    res.status(200).json({
      ResultCode: 0,
      ResultDesc: 'Accepted'
    });
  } catch (error) {
    console.error('M-Pesa webhook error:', error);
    res.status(500).json({
      ResultCode: 1,
      ResultDesc: 'Error processing payment'
    });
  }
});

/**
 * Extract payment data from M-Pesa Daraja payload
 */
function extractPaymentData(body) {
  try {
    // Daraja C2B callback structure
    const stkCallback = body.Body?.stkCallback;
    
    if (!stkCallback || stkCallback.ResultCode !== 0) {
      return null; // Payment failed or invalid
    }

    const callbackMetadata = stkCallback.CallbackMetadata?.Item || [];
    
    // Extract payment details
    const paymentData = {
      mpesa_ref: '',
      amount: 0,
      phone: '',
      timestamp: new Date().toISOString(),
      merchant_request_id: stkCallback.MerchantRequestID,
      checkout_request_id: stkCallback.CheckoutRequestID
    };

    callbackMetadata.forEach(item => {
      switch (item.Name) {
        case 'MpesaReceiptNumber':
          paymentData.mpesa_ref = item.Value;
          break;
        case 'Amount':
          paymentData.amount = item.Value;
          break;
        case 'PhoneNumber':
          paymentData.phone = item.Value;
          break;
        case 'TransactionDate':
          paymentData.timestamp = new Date(item.Value).toISOString();
          break;
      }
    });

    return paymentData;
  } catch (error) {
    console.error('Error extracting payment data:', error);
    return null;
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'mpesa-webhook', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`M-Pesa webhook server running on port ${PORT}`);
  console.log(`Webhook URL: http://localhost:${PORT}/webhook/mpesa`);
  console.log(`Forwarding to n8n: ${N8N_WEBHOOK_URL}`);
  console.log('Use ngrok to expose: ngrok http', PORT);
});



