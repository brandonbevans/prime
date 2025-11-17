-- Debug queries for local development
-- Run these in Supabase Studio SQL Editor or via CLI

-- View all auth users
SELECT 
    id,
    email,
    created_at,
    last_sign_in_at,
    email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- View all user profiles
SELECT 
    u.id,
    u.first_name,
    u.age,
    u.gender,
    u.primary_goal,
    u.coaching_style,
    u.onboarding_completed,
    u.created_at,
    au.email
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
ORDER BY u.created_at DESC;

-- Check if user exists in both tables
SELECT 
    au.email,
    au.id as auth_id,
    u.id as user_id,
    u.first_name,
    CASE 
        WHEN u.id IS NULL THEN 'No profile'
        WHEN u.onboarding_completed THEN 'Completed'
        ELSE 'In progress'
    END as status
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
ORDER BY au.created_at DESC;

-- View goals for all users
SELECT 
    au.email,
    u.first_name,
    g.goal_text,
    g.status,
    g.created_at
FROM public.goals g
JOIN public.users u ON g.user_id = u.id
JOIN auth.users au ON u.id = au.id
ORDER BY g.created_at DESC;

-- Delete test user (replace email)
-- WARNING: This cascades to all related data
DELETE FROM auth.users 
WHERE email = 'test@example.com';

-- Clear ALL test data (use with caution!)
-- TRUNCATE auth.users CASCADE;

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Test RLS as specific user (replace UUID)
-- SET LOCAL "request.jwt.claims" = '{"sub":"YOUR-USER-UUID-HERE"}';
-- SELECT * FROM public.users;
-- RESET "request.jwt.claims";

-- Count users by onboarding status
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN u.id IS NOT NULL THEN 1 END) as with_profile,
    COUNT(CASE WHEN u.onboarding_completed THEN 1 END) as completed_onboarding
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id;

-- Debug: Show recent authentication attempts
SELECT 
    id,
    email,
    last_sign_in_at,
    created_at,
    updated_at
FROM auth.users
WHERE last_sign_in_at > NOW() - INTERVAL '1 hour'
ORDER BY last_sign_in_at DESC;

-- Debug: Find orphaned user profiles (shouldn't exist with proper FK)
SELECT * FROM public.users
WHERE id NOT IN (SELECT id FROM auth.users);

-- Debug: Find auth users without profiles
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created,
    EXTRACT(EPOCH FROM (NOW() - au.created_at))/60 as minutes_since_creation
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL
ORDER BY au.created_at DESC;
