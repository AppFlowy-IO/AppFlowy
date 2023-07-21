-- Your SQL goes here
CREATE TABLE user_workspace_table (
 id TEXT PRIMARY KEY,
 name TEXT NOT NULL,
 created_at BIGINT NOT NULL DEFAULT 0,
 database_storage_id TEXT NOT NULL
);
