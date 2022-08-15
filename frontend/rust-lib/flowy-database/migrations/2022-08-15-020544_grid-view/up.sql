-- Your SQL goes here


CREATE TABLE grid_view_rev_table (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id TEXT NOT NULL DEFAULT '',
    base_rev_id BIGINT NOT NULL DEFAULT 0,
    rev_id BIGINT NOT NULL DEFAULT 0,
    data BLOB NOT NULL DEFAULT (x''),
    state INTEGER NOT NULL DEFAULT 0
);
