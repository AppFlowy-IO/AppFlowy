-- Add migration script here
CREATE TABLE IF NOT EXISTS trash_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    ty INTEGER NOT NULL DEFAULT 0
);