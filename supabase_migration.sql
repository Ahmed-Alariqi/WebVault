-- ===== BACKUP FIRST =====
CREATE TABLE IF NOT EXISTS websites_backup AS SELECT * FROM websites;

-- ===== MIGRATION =====
-- إضافة الأعمدة الجديدة لجدول websites
ALTER TABLE websites ADD COLUMN IF NOT EXISTS content_type TEXT DEFAULT 'website'
  CHECK (content_type IN ('website','prompt','offer','announcement'));
ALTER TABLE websites ADD COLUMN IF NOT EXISTS action_value TEXT DEFAULT '';
ALTER TABLE websites ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
ALTER TABLE websites ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- ===== ROLLBACK (نفّذ فقط إذا أردت إلغاء كل شيء) =====
-- ALTER TABLE websites DROP COLUMN IF EXISTS content_type;
-- ALTER TABLE websites DROP COLUMN IF EXISTS action_value;
-- ALTER TABLE websites DROP COLUMN IF EXISTS expires_at;
-- ALTER TABLE websites DROP COLUMN IF EXISTS is_active;
-- DROP TABLE IF EXISTS websites_backup;
