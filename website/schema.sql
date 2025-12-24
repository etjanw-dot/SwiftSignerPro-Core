-- =====================================================
-- SwiftSigner Pro - Add Missing Columns
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Add device_name column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS device_name TEXT;

-- Add device_type column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS device_type TEXT DEFAULT 'iPhone';

-- Add registered_at column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add is_free_preorder column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS is_free_preorder BOOLEAN DEFAULT true;

-- Add password_hash column for web login (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Add expires_at column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

-- Add ios_version column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS ios_version TEXT;

-- Add plan_type column (if missing)
ALTER TABLE registered_udids 
ADD COLUMN IF NOT EXISTS plan_type TEXT DEFAULT 'free';

-- =====================================================
-- After running this, refresh the Supabase schema cache:
-- Go to Settings > API > Click "Reload" next to schema cache
-- OR wait a few seconds and it should auto-refresh
-- =====================================================
