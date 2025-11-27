-- Add missing DELETE policy for user_profiles table
CREATE POLICY "Users can delete their own profile" ON public.user_profiles
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create a function to delete the current user's account
-- This function runs with elevated privileges (SECURITY DEFINER)
-- to allow deletion from auth.users which requires admin access
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the current user's ID
    current_user_id := auth.uid();
    
    -- Verify user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Delete from all user tables (CASCADE should handle most, but being explicit)
    -- Order matters due to foreign key constraints
    
    -- 1. Delete chat messages
    DELETE FROM public.chat_messages WHERE user_id = current_user_id;
    
    -- 2. Delete chat conversations
    DELETE FROM public.chat_conversations WHERE user_id = current_user_id;
    
    -- 3. Delete user notes
    DELETE FROM public.user_notes WHERE user_id = current_user_id;
    
    -- 4. Delete goals
    DELETE FROM public.goals WHERE user_id = current_user_id;
    
    -- 5. Delete sessions
    DELETE FROM public.sessions WHERE user_id = current_user_id;
    
    -- 6. Delete user profile
    DELETE FROM public.user_profiles WHERE user_id = current_user_id;
    
    -- 7. Delete the user from auth.users
    -- This requires SECURITY DEFINER as regular users can't delete from auth schema
    DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.delete_user_account() IS 'Deletes the current user account and all associated data. This is irreversible.';

