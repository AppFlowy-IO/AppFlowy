-- Your SQL goes here
CREATE TABLE recent_table (
    id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    prev_id TEXT,
    recent_at BIGINT NOT NULL
);