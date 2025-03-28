-- Your SQL goes here
CREATE TABLE favorite_table (
    id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    prev_id TEXT,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    favorite_at BIGINT NOT NULL
);