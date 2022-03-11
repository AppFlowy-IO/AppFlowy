-- Your SQL goes here
CREATE TABLE kv_table (
   key TEXT NOT NULL PRIMARY KEY,
   value BLOB NOT NULL DEFAULT (x'')
);