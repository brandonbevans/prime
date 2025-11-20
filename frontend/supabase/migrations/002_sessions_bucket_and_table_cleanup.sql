-- Ensure the private storage bucket used for session audio exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('sessions', 'sessions', FALSE)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public;

-- Tighten storage policies so each user can only manage their own audio objects
DROP POLICY IF EXISTS "Users can read their session audio" ON storage.objects;
CREATE POLICY "Users can read their session audio"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'sessions'
    AND name LIKE 'sessions/' || auth.uid()::text || '/%'
  );

DROP POLICY IF EXISTS "Users can upload their session audio" ON storage.objects;
CREATE POLICY "Users can upload their session audio"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'sessions'
    AND name LIKE 'sessions/' || auth.uid()::text || '/%'
  );

DROP POLICY IF EXISTS "Users can delete their session audio" ON storage.objects;
CREATE POLICY "Users can delete their session audio"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'sessions'
    AND name LIKE 'sessions/' || auth.uid()::text || '/%'
  );

-- Trim the sessions table down to just id, user_id, created_at
ALTER TABLE public.sessions
  DROP COLUMN IF EXISTS mood,
  DROP COLUMN IF EXISTS trajectory_feeling,
  DROP COLUMN IF EXISTS motivation_shift,
  DROP COLUMN IF EXISTS obstacles,
  DROP COLUMN IF EXISTS accountability_preference,
  DROP COLUMN IF EXISTS session_type,
  DROP COLUMN IF EXISTS duration_minutes,
  DROP COLUMN IF EXISTS notes;

