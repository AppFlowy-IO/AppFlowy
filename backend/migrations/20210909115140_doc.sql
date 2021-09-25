-- Add migration script here
CREATE TABLE IF NOT EXISTS doc_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    data bytea NOT NULL DEFAULT '',
    rev_id bigint NOT NULL DEFAULT 0
);