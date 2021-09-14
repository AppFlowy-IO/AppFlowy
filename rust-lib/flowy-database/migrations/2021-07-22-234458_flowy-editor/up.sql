-- Your SQL goes here
CREATE TABLE doc_table (
    id TEXT NOT NULL PRIMARY KEY,
    data BLOB NOT NULL DEFAULT (x''),
    version BIGINT NOT NULL DEFAULT 0
);