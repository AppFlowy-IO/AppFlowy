-- Add migration script here
CREATE TABLE IF NOT EXISTS trash_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    user_id TEXT NOT NULL,
    ty INTEGER NOT NULL DEFAULT 0
);