-- Your SQL goes here
CREATE TABLE workspace_members_table (
    email TEXT KEY NOT NULL,
    role INTEGER NOT NULL,
    name TEXT NOT NULL,
    avatar_url TEXT,
    uid BIGINT NOT NULL,
    workspace_id TEXT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email, workspace_id)
);