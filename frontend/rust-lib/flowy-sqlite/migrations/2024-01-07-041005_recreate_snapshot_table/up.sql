-- Your SQL goes here
-- Drop the table if it exists
DROP TABLE IF EXISTS rocksdb_backup;
DROP TABLE IF EXISTS collab_snapshot;

-- Recreate the table
CREATE TABLE collab_snapshot (
   id TEXT NOT NULL PRIMARY KEY DEFAULT '',
   object_id TEXT NOT NULL DEFAULT '',
   title TEXT NOT NULL DEFAULT '',
   desc TEXT NOT NULL DEFAULT '',
   collab_type TEXT NOT NULL DEFAULT '',
   timestamp BIGINT NOT NULL DEFAULT 0,
   data BLOB NOT NULL DEFAULT (x'')
);