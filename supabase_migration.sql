-- ===== INTERACTIVE GIVEAWAY FEATURES MIGRATION =====
-- Run this in Supabase SQL Editor

-- 1. Add email to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Sync existing emails from auth.users
UPDATE profiles SET email = u.email
FROM auth.users u WHERE profiles.id = u.id;

-- 3. Update (or create) new-user trigger to copy email
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make sure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. Giveaway new columns
ALTER TABLE giveaways ADD COLUMN IF NOT EXISTS entry_field_label TEXT DEFAULT NULL;
ALTER TABLE giveaways ADD COLUMN IF NOT EXISTS winner_count INTEGER DEFAULT 1;
ALTER TABLE giveaways ADD COLUMN IF NOT EXISTS winner_ids JSONB DEFAULT '[]'::jsonb;

-- 5. Giveaway entries new column
ALTER TABLE giveaway_entries ADD COLUMN IF NOT EXISTS entry_value TEXT DEFAULT NULL;

-- ===== DONE =====
