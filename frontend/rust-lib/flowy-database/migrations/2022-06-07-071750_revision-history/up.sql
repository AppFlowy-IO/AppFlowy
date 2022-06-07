-- Your SQL goes here
CREATE TABLE rev_history (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id TEXT NOT NULL DEFAULT '',
    start_rev_id BIGINT NOT NULL DEFAULT 0,
    end_rev_id BIGINT NOT NULL DEFAULT 0,
    data BLOB NOT NULL DEFAULT (x'')
);