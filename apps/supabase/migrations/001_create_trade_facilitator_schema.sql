-- Trade Facilitator Database Schema
-- Creates all tables for hub-and-spoke model: Single WABA orchestrating buyer-seller trades
-- 
-- Architecture: See docs/WAAS_ARCHITECTURE.md (Layer 1: System of Record)
-- Data Model: See docs/TRADE_FACILITATOR_ARCHITECTURE.md (7-Table Data Model)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Buyers Table
CREATE TABLE buyers (
  buyer_id TEXT PRIMARY KEY DEFAULT 'B' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('buyer_seq')::TEXT, 4, '0'),
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  preferred_delivery_area TEXT, -- CBD, Eastleigh, Westlands, etc.
  total_trades INT DEFAULT 0,
  total_spent DECIMAL DEFAULT 0,
  last_trade_at TIMESTAMPTZ,
  last_message_at TIMESTAMPTZ, -- Track 24h conversation window
  conversation_window_expires_at TIMESTAMPTZ, -- 24h from last_message_at
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for buyer_id
CREATE SEQUENCE IF NOT EXISTS buyer_seq;

-- Sellers Table
CREATE TABLE sellers (
  seller_id TEXT PRIMARY KEY DEFAULT 'S' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('seller_seq')::TEXT, 4, '0'),
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  business_name TEXT,
  mpesa_till_number TEXT, -- For payouts
  total_trades INT DEFAULT 0,
  total_revenue DECIMAL DEFAULT 0,
  total_payouts DECIMAL DEFAULT 0,
  last_trade_at TIMESTAMPTZ,
  last_message_at TIMESTAMPTZ, -- Track 24h conversation window
  conversation_window_expires_at TIMESTAMPTZ, -- 24h from last_message_at
  status TEXT DEFAULT 'active', -- active, suspended, inactive
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for seller_id
CREATE SEQUENCE IF NOT EXISTS seller_seq;

-- Products Table (Seller catalog)
CREATE TABLE products (
  product_id TEXT PRIMARY KEY DEFAULT 'P' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('product_seq')::TEXT, 4, '0'),
  seller_id TEXT NOT NULL REFERENCES sellers(seller_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price_kes DECIMAL NOT NULL,
  image_url TEXT, -- WhatsApp media URL
  category TEXT, -- Fabric, Electronics, Food, etc.
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for product_id
CREATE SEQUENCE IF NOT EXISTS product_seq;

-- Trades Table (Central entity)
CREATE TABLE trades (
  trade_id TEXT PRIMARY KEY DEFAULT 'TR' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('trade_seq')::TEXT, 5, '0'),
  buyer_id TEXT NOT NULL REFERENCES buyers(buyer_id),
  buyer_phone TEXT NOT NULL,
  seller_id TEXT NOT NULL REFERENCES sellers(seller_id),
  seller_phone TEXT NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(product_id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL NOT NULL,
  total_amount DECIMAL NOT NULL,
  platform_fee DECIMAL DEFAULT 50, -- Transaction fee (KSh 50-100)
  payout_amount DECIMAL NOT NULL, -- Amount to seller (total_amount - platform_fee)
  delivery_area TEXT, -- CBD, Eastleigh, Westlands, etc.
  delivery_address TEXT, -- Full delivery address (optional)
  status TEXT DEFAULT 'pending', -- pending, confirmed, paid, dispatched, delivered, completed, cancelled
  buyer_confirmed_delivery BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  dispatched_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  buyer_conversation_id TEXT, -- WhatsApp conversation ID for buyer
  seller_conversation_id TEXT, -- WhatsApp conversation ID for seller
  notes TEXT -- Additional notes or instructions
);

-- Create sequence for trade_id
CREATE SEQUENCE IF NOT EXISTS trade_seq;

-- Conversations Table (Track conversation windows)
CREATE TABLE conversations (
  conversation_id TEXT PRIMARY KEY DEFAULT 'CONV' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('conversation_seq')::TEXT, 6, '0'),
  user_phone TEXT NOT NULL, -- Buyer or seller phone
  user_type TEXT NOT NULL CHECK (user_type IN ('buyer', 'seller')), -- 'buyer' or 'seller'
  trade_id TEXT REFERENCES trades(trade_id),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- 24h from last_message_at
  message_count INT DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'closed'))
);

-- Create sequence for conversation_id
CREATE SEQUENCE IF NOT EXISTS conversation_seq;

-- Payments Table
CREATE TABLE payments (
  payment_id TEXT PRIMARY KEY DEFAULT 'PAY' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('payment_seq')::TEXT, 6, '0'),
  trade_id TEXT NOT NULL REFERENCES trades(trade_id),
  amount_kes DECIMAL NOT NULL,
  mpesa_ref TEXT, -- M-Pesa receipt number
  payment_type TEXT DEFAULT 'stk_push' CHECK (payment_type IN ('stk_push', 'paybill', 'till')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  checkout_request_id TEXT, -- STK push checkout request ID
  paid_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for payment_id
CREATE SEQUENCE IF NOT EXISTS payment_seq;

-- Payouts Table
CREATE TABLE payouts (
  payout_id TEXT PRIMARY KEY DEFAULT 'PO' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('payout_seq')::TEXT, 6, '0'),
  trade_id TEXT NOT NULL REFERENCES trades(trade_id),
  seller_id TEXT NOT NULL REFERENCES sellers(seller_id),
  amount_kes DECIMAL NOT NULL,
  mpesa_ref TEXT, -- M-Pesa payout reference
  originator_conversation_id TEXT, -- B2C payout conversation ID
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  paid_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sequence for payout_id
CREATE SEQUENCE IF NOT EXISTS payout_seq;

-- Indexes for Performance
CREATE INDEX idx_buyers_phone ON buyers(phone);
CREATE INDEX idx_buyers_conversation_window ON buyers(conversation_window_expires_at);
CREATE INDEX idx_sellers_phone ON sellers(phone);
CREATE INDEX idx_sellers_conversation_window ON sellers(conversation_window_expires_at);
CREATE INDEX idx_sellers_status ON sellers(status);
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_active ON products(active);
CREATE INDEX idx_trades_buyer_id ON trades(buyer_id);
CREATE INDEX idx_trades_seller_id ON trades(seller_id);
CREATE INDEX idx_trades_status ON trades(status);
CREATE INDEX idx_trades_created_at ON trades(created_at);
CREATE INDEX idx_trades_buyer_phone ON trades(buyer_phone);
CREATE INDEX idx_trades_seller_phone ON trades(seller_phone);
CREATE INDEX idx_conversations_user_phone ON conversations(user_phone);
CREATE INDEX idx_conversations_user_type ON conversations(user_type);
CREATE INDEX idx_conversations_trade_id ON conversations(trade_id);
CREATE INDEX idx_conversations_expires_at ON conversations(expires_at);
CREATE INDEX idx_payments_trade_id ON payments(trade_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_mpesa_ref ON payments(mpesa_ref);
CREATE INDEX idx_payouts_trade_id ON payouts(trade_id);
CREATE INDEX idx_payouts_seller_id ON payouts(seller_id);
CREATE INDEX idx_payouts_status ON payouts(status);

-- Functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_buyers_updated_at BEFORE UPDATE ON buyers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sellers_updated_at BEFORE UPDATE ON sellers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payouts_updated_at BEFORE UPDATE ON payouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation window expiry
CREATE OR REPLACE FUNCTION update_conversation_window()
RETURNS TRIGGER AS $$
BEGIN
  -- Update conversation window expiry (24h from last_message_at)
  IF TG_TABLE_NAME = 'buyers' THEN
    UPDATE buyers SET conversation_window_expires_at = last_message_at + INTERVAL '24 hours'
    WHERE buyer_id = NEW.buyer_id;
  ELSIF TG_TABLE_NAME = 'sellers' THEN
    UPDATE sellers SET conversation_window_expires_at = last_message_at + INTERVAL '24 hours'
    WHERE seller_id = NEW.seller_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate payout_amount automatically
CREATE OR REPLACE FUNCTION calculate_payout_amount()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate payout_amount = total_amount - platform_fee
  NEW.payout_amount = NEW.total_amount - COALESCE(NEW.platform_fee, 50);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for automatic payout_amount calculation
CREATE TRIGGER calculate_trade_payout_amount BEFORE INSERT OR UPDATE ON trades
  FOR EACH ROW EXECUTE FUNCTION calculate_payout_amount();

-- Row-Level Security (RLS) Policies
-- Note: RLS should be enabled per trader if multi-tenancy needed
-- For Trade Facilitator model, all data is visible to platform
-- Only enable RLS if needed for future multi-tenant scenarios

-- Enable RLS (commented out for now - uncomment if needed)
-- ALTER TABLE buyers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

-- Grant permissions (adjust based on your Supabase setup)
-- GRANT USAGE ON SCHEMA public TO authenticated;
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

