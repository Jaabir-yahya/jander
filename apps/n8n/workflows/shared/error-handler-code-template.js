/**
 * n8n Code Node Template: Error Handler with Retry Logic
 * 
 * Copy this code into an n8n Code node to add error handling to any workflow
 * 
 * Usage:
 * 1. Add this as a Code node after your main operation
 * 2. Wrap your operation in the try-catch block
 * 3. Configure maxRetries and baseDelayMs as needed
 * 
 * Architecture: Error Handling & Resilience (Phase 3)
 * Date: January 9, 2026
 */

// Error classifications
const ERROR_CLASSIFICATIONS = {
  RETRYABLE: 'RETRYABLE',
  NEEDS_REVIEW: 'NEEDS_REVIEW',
  CRITICAL: 'CRITICAL'
};

// Classify error
function classifyError(error) {
  const errorMessage = (error?.message || '').toLowerCase();
  const errorCode = error?.code || error?.status || '';
  
  if (
    errorCode === 'ECONNREFUSED' ||
    errorCode === 'ETIMEDOUT' ||
    errorCode === 429 ||
    errorCode === 503 ||
    errorMessage.includes('timeout') ||
    errorMessage.includes('rate limit')
  ) {
    return ERROR_CLASSIFICATIONS.RETRYABLE;
  }
  
  if (
    errorCode === 400 ||
    errorCode === 422 ||
    errorMessage.includes('validation') ||
    errorMessage.includes('invalid')
  ) {
    return ERROR_CLASSIFICATIONS.NEEDS_REVIEW;
  }
  
  if (
    errorCode === 401 ||
    errorCode === 403 ||
    errorMessage.includes('unauthorized')
  ) {
    return ERROR_CLASSIFICATIONS.CRITICAL;
  }
  
  return ERROR_CLASSIFICATIONS.NEEDS_REVIEW;
}

// Calculate retry delay (exponential backoff with jitter)
function calculateRetryDelay(attempt, baseDelayMs = 1000) {
  const exponentialDelay = Math.min(baseDelayMs * Math.pow(2, attempt), 3600000);
  const jitter = Math.random() * exponentialDelay * 0.1;
  return Math.floor(exponentialDelay + jitter);
}

// Main error handler
const input = $input.item.json;
const operation = input.operation || 'unknown_operation';
const maxRetries = input.max_retries || 3;
const baseDelayMs = input.base_delay_ms || 1000;
const tenantId = input.tenant_id || null;

let lastError;
let attempt = 0;

// Your operation function (replace with actual operation)
async function executeOperation() {
  // TODO: Replace with your actual operation
  // Example:
  // const result = await someApiCall();
  // return result;
  
  throw new Error('Operation not implemented');
}

// Retry loop
for (attempt = 0; attempt < maxRetries; attempt++) {
  try {
    const result = await executeOperation();
    
    return {
      success: true,
      result: result,
      attempt: attempt + 1,
      ...input
    };
  } catch (error) {
    lastError = error;
    const classification = classifyError(error);
    
    // Don't retry if not retryable
    if (classification !== ERROR_CLASSIFICATIONS.RETRYABLE) {
      return {
        success: false,
        error: error.message,
        classification: classification,
        attempt: attempt + 1,
        requires_manual_review: classification === ERROR_CLASSIFICATIONS.NEEDS_REVIEW,
        ...input
      };
    }
    
    // Calculate delay and wait
    if (attempt < maxRetries - 1) {
      const delayMs = calculateRetryDelay(attempt, baseDelayMs);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
}

// All retries exhausted - add to dead letter queue
const classification = classifyError(lastError);

// Insert into dead letter queue (if Supabase configured)
if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    
    // Note: In n8n, you'd use HTTP Request node to insert into DLQ
    // This is just the pattern - actual implementation uses HTTP Request node
  } catch (dlqError) {
    // DLQ insertion failed - log but don't fail
  }
}

return {
  success: false,
  error: lastError.message,
  classification: classification,
  attempt: attempt,
  max_retries_exceeded: true,
  requires_manual_review: true,
  ...input
};

