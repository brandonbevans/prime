-- Create user_notes table for AI-generated insights about users
-- These notes help Gemini remember important details across conversations
CREATE TABLE IF NOT EXISTS public.user_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Note content
    category TEXT NOT NULL CHECK (category IN (
        'goal',           -- Goals and aspirations
        'challenge',      -- Obstacles or struggles
        'preference',     -- Preferences and styles
        'achievement',    -- Wins and progress
        'insight',        -- Personal insights or realizations
        'context',        -- Background information
        'reminder'        -- Things to follow up on
    )),
    content TEXT NOT NULL,
    
    -- Source tracking
    source_conversation_id UUID REFERENCES public.chat_conversations(id) ON DELETE SET NULL,
    
    -- Note status
    is_active BOOLEAN DEFAULT TRUE,  -- Can be deactivated if no longer relevant
    importance INTEGER DEFAULT 1 CHECK (importance >= 1 AND importance <= 5)  -- 1=low, 5=high
);

-- Create indexes for efficient queries
CREATE INDEX idx_user_notes_user_id ON public.user_notes(user_id);
CREATE INDEX idx_user_notes_category ON public.user_notes(category);
CREATE INDEX idx_user_notes_created_at ON public.user_notes(created_at DESC);
CREATE INDEX idx_user_notes_active ON public.user_notes(is_active) WHERE is_active = TRUE;

-- Enable RLS
ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their own notes" ON public.user_notes
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notes" ON public.user_notes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes" ON public.user_notes
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes" ON public.user_notes
    FOR DELETE
    USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_user_notes_updated_at 
    BEFORE UPDATE ON public.user_notes
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE public.user_notes IS 'AI-generated notes about users to provide context across conversations';
COMMENT ON COLUMN public.user_notes.category IS 'Type of insight: goal, challenge, preference, achievement, insight, context, reminder';
COMMENT ON COLUMN public.user_notes.importance IS 'Priority level 1-5, higher = more important to remember';

