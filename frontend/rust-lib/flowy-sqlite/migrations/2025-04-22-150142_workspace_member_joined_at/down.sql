-- This file should undo anything in `up.sql`
ALTER TABLE workspace_members_table
DROP COLUMN joined_at;
