-- This file should undo anything in `up.sql`
ALTER TABLE chat_table
    ADD COLUMN local_enabled INTEGER;
ALTER TABLE chat_table
    ADD COLUMN sync_to_cloud INTEGER;
ALTER TABLE chat_table
    ADD COLUMN local_files TEXT;

ALTER TABLE chat_table DROP COLUMN rag_ids;
