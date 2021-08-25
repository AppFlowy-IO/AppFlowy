-- Add migration script here
CREATE TABLE IF NOT EXISTS app_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    color_style BYTEA NOT NULL,
    last_view_id TEXT DEFAULT '',
    modified_time timestamptz NOT NULL,
    create_time timestamptz NOT NULL,
    user_id TEXT NOT NULL,
    is_trash BOOL NOT NULL DEFAULT false
);