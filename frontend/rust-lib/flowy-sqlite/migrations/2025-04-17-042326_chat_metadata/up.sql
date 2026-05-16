ALTER TABLE chat_table DROP COLUMN local_enabled;
ALTER TABLE chat_table DROP COLUMN local_files;
ALTER TABLE chat_table DROP COLUMN sync_to_cloud;
ALTER TABLE chat_table ADD COLUMN rag_ids TEXT;