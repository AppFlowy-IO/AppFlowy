-- Your SQL goes here
CREATE TABLE folder_table (
    id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT,
    is_space BOOLEAN NOT NULL DEFAULT FALSE,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    layout INTEGER NOT NULL DEFAULT 0,
    created_at BIGINT NOT NULL,
    last_edited_time BIGINT NOT NULL,
    is_locked BOOLEAN,
    parent_id TEXT,
    sync_status TEXT NOT NULL,
    last_modified_time BIGINT NOT NULL,
    extra TEXT
);
