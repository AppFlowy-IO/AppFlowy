-- Your SQL goes here
CREATE TABLE rev_snapshot (
     id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     object_id TEXT NOT NULL DEFAULT '',
     rev_id BIGINT NOT NULL DEFAULT 0,
     data BLOB NOT NULL DEFAULT (x'')
);