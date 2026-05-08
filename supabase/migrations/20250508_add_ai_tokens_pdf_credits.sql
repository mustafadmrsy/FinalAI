-- Add AI token and PDF credit columns to user_stats table
-- ai_tokens: AI feature usage tokens (default 5 for new users)
-- pdf_credits: PDF summary credits (default 3 for new users)

ALTER TABLE user_stats
  ADD COLUMN IF NOT EXISTS ai_tokens integer NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS pdf_credits integer NOT NULL DEFAULT 3;

-- Set existing users to default values
UPDATE user_stats SET ai_tokens = 5 WHERE ai_tokens IS NULL;
UPDATE user_stats SET pdf_credits = 3 WHERE pdf_credits IS NULL;
