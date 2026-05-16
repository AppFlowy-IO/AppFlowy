-- This file should undo anything in `up.sql`
ALTER TABLE chat_table DROP COLUMN is_sync;
ALTER TABLE chat_message_table DROP COLUMN is_sync;
