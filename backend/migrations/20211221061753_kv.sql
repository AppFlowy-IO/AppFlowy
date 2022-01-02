-- Add migration script here
CREATE TABLE IF NOT EXISTS kv_table(
    id TEXT NOT NULL,
    PRIMARY KEY (id),
    blob bytea
);