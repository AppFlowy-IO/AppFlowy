-- Your SQL goes here
CREATE TABLE trash_table (
    id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    prev_id TEXT,
    deleted_at BIGINT NOT NULL
);