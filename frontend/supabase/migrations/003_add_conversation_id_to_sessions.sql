-- Add ElevenLabs conversation ID to the sessions table
ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS elevenlabs_conversation_id TEXT UNIQUE;

-- Ensure fast lookups when searching by conversation id
CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_conversation_id
  ON public.sessions(elevenlabs_conversation_id)
  WHERE elevenlabs_conversation_id IS NOT NULL;

