-- Your SQL goes here
ALTER TABLE chat_table ADD COLUMN local_model_path TEXT NOT NULL DEFAULT '';
ALTER TABLE chat_table ADD COLUMN local_model_name TEXT NOT NULL DEFAULT '';
ALTER TABLE chat_table ADD COLUMN local_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE chat_table ADD COLUMN sync_to_cloud BOOLEAN NOT NULL DEFAULT TRUE;


CREATE TABLE chat_local_setting_table
(
    chat_id TEXT PRIMARY KEY NOT NULL,
    local_model_path TEXT NOT NULL,
    local_model_name TEXT NOT NULL DEFAULT ''
);