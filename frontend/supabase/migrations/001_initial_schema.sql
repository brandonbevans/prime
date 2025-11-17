-- Create user_profiles table to store onboarding data not present in auth.users
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic user info
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    first_name TEXT NOT NULL,
    age INTEGER CHECK (age > 0 AND age <= 120),
    
    -- Goal information
    goal_recency VARCHAR(50) CHECK (goal_recency IN (
        'lastWeek', 
        'lastMonth', 
        'lastYear', 
        'cantRemember'
    )),
    primary_goal TEXT NOT NULL,
    goal_visualization TEXT NOT NULL,
    micro_action TEXT NOT NULL,
    
    -- Coaching preferences
    coaching_style VARCHAR(50) CHECK (coaching_style IN (
        'direct',
        'dataDriven',
        'encouraging',
        'reflective'
    )),
    
    -- Onboarding metadata
    onboarding_completed BOOLEAN DEFAULT FALSE,
    onboarding_completed_at TIMESTAMPTZ,
    last_completed_step VARCHAR(50)
);

-- Create index for faster queries
CREATE INDEX idx_user_profiles_onboarding_completed ON public.user_profiles(onboarding_completed);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only read and update their own data
CREATE POLICY "Users can view their own data" ON public.user_profiles
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own data" ON public.user_profiles
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own data" ON public.user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create goals table for tracking user goals over time (future enhancement)
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    goal_text TEXT NOT NULL,
    visualization_text TEXT,
    micro_action TEXT,
    
    -- Goal status tracking
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN (
        'active',
        'completed',
        'paused',
        'cancelled'
    )),
    completed_at TIMESTAMPTZ,
    
    -- Goal metadata
    goal_type VARCHAR(50),
    target_date DATE,
    notes TEXT
);

-- Create index for goal queries
CREATE INDEX idx_goals_user_id ON public.goals(user_id);
CREATE INDEX idx_goals_status ON public.goals(status);
CREATE INDEX idx_goals_created_at ON public.goals(created_at DESC);

-- Enable RLS for goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for goals
CREATE POLICY "Users can view their own goals" ON public.goals
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals" ON public.goals
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" ON public.goals
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals" ON public.goals
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to update goals updated_at
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON public.goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create sessions table for tracking user sessions and mood (future enhancement)
CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Session data
    mood VARCHAR(50),
    trajectory_feeling VARCHAR(50),
    motivation_shift VARCHAR(50),
    obstacles TEXT[],
    accountability_preference VARCHAR(100),
    
    -- Session metadata
    session_type VARCHAR(50),
    duration_minutes INTEGER,
    notes TEXT
);

-- Create index for sessions
CREATE INDEX idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX idx_sessions_created_at ON public.sessions(created_at DESC);

-- Enable RLS for sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for sessions
CREATE POLICY "Users can view their own sessions" ON public.sessions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions" ON public.sessions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sessions" ON public.sessions
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions" ON public.sessions
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add helpful comments
COMMENT ON TABLE public.user_profiles IS 'Main user profile table storing onboarding information not present in auth.users';
COMMENT ON TABLE public.goals IS 'User goals tracking table for historical goal management';
COMMENT ON TABLE public.sessions IS 'User coaching sessions and check-ins';
COMMENT ON COLUMN public.user_profiles.goal_recency IS 'How recently the user thought about their goal';
COMMENT ON COLUMN public.user_profiles.coaching_style IS 'Preferred coaching communication style';
