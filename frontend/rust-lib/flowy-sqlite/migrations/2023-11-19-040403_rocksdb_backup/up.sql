-- Your SQL goes here
CREATE TABLE rocksdb_backup (
  object_id TEXT NOT NULL PRIMARY KEY,
  timestamp BIGINT NOT NULL DEFAULT 0,
  data BLOB NOT NULL DEFAULT (x'')
);
