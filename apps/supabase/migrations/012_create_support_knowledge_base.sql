-- Support Knowledge Base & Community Q&A System
-- Part of Nairobi Super Suite: Emergency Support Infrastructure
-- 
-- Purpose: Tier 2 Community Support to scale to 50+ tenants
-- Architecture: See docs/SPEC_COMPLIANCE_ACTION_PLAN.md
-- 
-- Date: January 9, 2026

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- KNOWLEDGE BASE ARTICLES
-- ============================================

CREATE TABLE IF NOT EXISTS knowledge_base_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL, -- URL-friendly identifier
  content TEXT NOT NULL,
  summary TEXT, -- Short preview (150 chars)
  tags TEXT[], -- ['instagram', 'mpesa', 'whatsapp', 'payment', 'setup']
  category TEXT, -- 'setup', 'troubleshooting', 'features', 'billing'
  views INT DEFAULT 0,
  helpful_count INT DEFAULT 0,
  not_helpful_count INT DEFAULT 0,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL = system-wide article
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES tenants(id), -- Who created this article
  is_published BOOLEAN DEFAULT true,
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(content, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(tags, ' '), '')), 'C')
  ) STORED
);

-- Full-text search index
CREATE INDEX IF NOT EXISTS knowledge_base_search_idx 
ON knowledge_base_articles USING gin(search_vector);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_kb_articles_category ON knowledge_base_articles(category);
CREATE INDEX IF NOT EXISTS idx_kb_articles_tags ON knowledge_base_articles USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_kb_articles_tenant ON knowledge_base_articles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_kb_articles_published ON knowledge_base_articles(is_published, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kb_articles_slug ON knowledge_base_articles(slug);

-- ============================================
-- COMMUNITY Q&A SYSTEM
-- ============================================

CREATE TABLE IF NOT EXISTS community_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  question_details TEXT, -- Additional context
  asked_by_phone TEXT, -- Customer phone number
  status TEXT DEFAULT 'open', -- 'open', 'answered', 'closed', 'escalated'
  answer TEXT,
  answered_by_tenant_id UUID REFERENCES tenants(id), -- Peer who answered
  answered_at TIMESTAMPTZ,
  helpful_count INT DEFAULT 0,
  tags TEXT[], -- Auto-tagged from question content
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(question, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(question_details, '')), 'B')
  ) STORED
);

-- Full-text search index
CREATE INDEX IF NOT EXISTS community_questions_search_idx 
ON community_questions USING gin(search_vector);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_community_questions_status ON community_questions(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_questions_tenant ON community_questions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_community_questions_tags ON community_questions USING gin(tags);

-- ============================================
-- SUPPORT SUCCESS LOGS
-- ============================================

CREATE TABLE IF NOT EXISTS support_success_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  error_type TEXT, -- 'payment_not_found', 'instagram_not_working', etc.
  knowledge_base_article_id UUID REFERENCES knowledge_base_articles(id) ON DELETE SET NULL,
  question_id UUID REFERENCES community_questions(id) ON DELETE SET NULL,
  resolved BOOLEAN DEFAULT false, -- Did the article/question solve the issue?
  resolution_time_seconds INT, -- How long to resolve
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_logs_error_type ON support_success_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_support_logs_article ON support_success_logs(knowledge_base_article_id);
CREATE INDEX IF NOT EXISTS idx_support_logs_resolved ON support_success_logs(resolved, created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE knowledge_base_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_success_logs ENABLE ROW LEVEL SECURITY;

-- Knowledge Base: System-wide articles visible to all, tenant-specific visible to tenant
CREATE POLICY knowledge_base_read ON knowledge_base_articles
  FOR SELECT
  USING (
    is_published = true AND (
      tenant_id IS NULL OR -- System-wide article
      tenant_id IN (
        SELECT id FROM tenants 
        WHERE id = auth.uid() 
        OR id IN (
          SELECT tenant_uuid FROM tenant_config 
          WHERE tenant_id = current_setting('app.tenant_id', true)
        )
      )
    )
  );

CREATE POLICY knowledge_base_write ON knowledge_base_articles
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

-- Community Questions: Tenants can see all open questions, their own questions, and answered questions
CREATE POLICY community_questions_read ON community_questions
  FOR SELECT
  USING (
    status = 'open' OR -- All open questions visible
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    ) OR
    status = 'answered' -- Answered questions visible to all
  );

CREATE POLICY community_questions_write ON community_questions
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

-- Support Success Logs: Tenant-specific
CREATE POLICY support_logs_isolation ON support_success_logs
  FOR ALL
  USING (
    tenant_id IN (
      SELECT id FROM tenants 
      WHERE id = auth.uid() 
      OR id IN (
        SELECT tenant_uuid FROM tenant_config 
        WHERE tenant_id = current_setting('app.tenant_id', true)
      )
    )
  );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Search Knowledge Base
CREATE OR REPLACE FUNCTION search_knowledge_base(p_query TEXT, p_category TEXT DEFAULT NULL, p_tags TEXT[] DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  title TEXT,
  summary TEXT,
  category TEXT,
  tags TEXT[],
  views INT,
  helpful_count INT,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    kb.id,
    kb.title,
    kb.summary,
    kb.category,
    kb.tags,
    kb.views,
    kb.helpful_count,
    ts_rank(kb.search_vector, plainto_tsquery('english', p_query)) as score
  FROM knowledge_base_articles kb
  WHERE kb.is_published = true
    AND kb.search_vector @@ plainto_tsquery('english', p_query)
    AND (p_category IS NULL OR kb.category = p_category)
    AND (p_tags IS NULL OR kb.tags && p_tags)
  ORDER BY score DESC, kb.views DESC, kb.helpful_count DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Function: Search Community Questions
CREATE OR REPLACE FUNCTION search_community_questions(p_query TEXT, p_status TEXT DEFAULT 'open')
RETURNS TABLE (
  id UUID,
  question TEXT,
  status TEXT,
  answer TEXT,
  helpful_count INT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cq.id,
    cq.question,
    cq.status,
    cq.answer,
    cq.helpful_count,
    cq.created_at,
    ts_rank(cq.search_vector, plainto_tsquery('english', p_query)) as score
  FROM community_questions cq
  WHERE cq.status = p_status
    AND cq.search_vector @@ plainto_tsquery('english', p_query)
  ORDER BY score DESC, cq.created_at DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Function: Mark Article as Helpful
CREATE OR REPLACE FUNCTION mark_article_helpful(p_article_id UUID, p_helpful BOOLEAN)
RETURNS VOID AS $$
BEGIN
  IF p_helpful THEN
    UPDATE knowledge_base_articles 
    SET helpful_count = helpful_count + 1
    WHERE id = p_article_id;
  ELSE
    UPDATE knowledge_base_articles 
    SET not_helpful_count = not_helpful_count + 1
    WHERE id = p_article_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Update Article Views
CREATE OR REPLACE FUNCTION increment_article_views(p_article_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE knowledge_base_articles 
  SET views = views + 1
  WHERE id = p_article_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE knowledge_base_articles IS 'Knowledge base articles for self-service support. System-wide articles (tenant_id = NULL) visible to all tenants.';
COMMENT ON TABLE community_questions IS 'Community Q&A system where tenants can ask and answer questions. Peer-to-peer support.';
COMMENT ON TABLE support_success_logs IS 'Tracks which articles/questions solve which issues. Used for analytics and improvement.';
COMMENT ON FUNCTION search_knowledge_base IS 'Full-text search across knowledge base articles with category and tag filtering.';
COMMENT ON FUNCTION search_community_questions IS 'Full-text search across community questions.';
COMMENT ON FUNCTION mark_article_helpful IS 'Increment helpful or not_helpful count for an article.';
COMMENT ON FUNCTION increment_article_views IS 'Increment view count when article is accessed.';

