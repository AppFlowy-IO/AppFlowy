-- Your SQL goes here
CREATE TABLE doc_table (
    id TEXT NOT NULL PRIMARY KEY,
--     data BLOB NOT NULL DEFAULT (x''),
    data TEXT NOT NULL DEFAULT '',
    rev_id BIGINT NOT NULL DEFAULT 0
);