-- Add migration script here
CREATE TABLE IF NOT EXISTS doc_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    data TEXT NOT NULL
);