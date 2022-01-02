-- Add migration script here
CREATE TABLE IF NOT EXISTS doc_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    rev_id bigint NOT NULL DEFAULT 0
);