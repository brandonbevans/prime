-- Remove first_name, age, and gender columns from user_profiles
-- These are no longer collected during onboarding (name comes from Sign In with Apple)

-- Drop the columns
ALTER TABLE public.user_profiles 
  DROP COLUMN IF EXISTS first_name,
  DROP COLUMN IF EXISTS age,
  DROP COLUMN IF EXISTS gender;

-- Update the table comment
COMMENT ON TABLE public.user_profiles IS 'User profile table storing onboarding preferences and goal information';

