-- Your SQL goes here
CREATE TABLE doc_table (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    desc TEXT NOT NULL DEFAULT '',
    path TEXT NOT NULL DEFAULT '',
    modified_time BIGINT NOT NULL DEFAULT 0,
    create_time BIGINT NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0
);