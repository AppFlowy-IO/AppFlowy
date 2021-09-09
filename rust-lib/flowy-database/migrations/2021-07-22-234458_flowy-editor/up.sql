-- Your SQL goes here
CREATE TABLE doc_table (
    id TEXT NOT NULL PRIMARY KEY,
    data TEXT NOT NULL DEFAULT '',
    version BIGINT NOT NULL DEFAULT 0
);