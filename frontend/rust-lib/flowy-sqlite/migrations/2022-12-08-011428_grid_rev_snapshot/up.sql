-- Your SQL goes here
CREATE TABLE grid_rev_snapshot (
      snapshot_id TEXT NOT NULL PRIMARY KEY DEFAULT '',
      object_id TEXT NOT NULL DEFAULT '',
      rev_id BIGINT NOT NULL DEFAULT 0,
      base_rev_id BIGINT NOT NULL DEFAULT 0,
      timestamp BIGINT NOT NULL DEFAULT 0,
      data BLOB NOT NULL DEFAULT (x'')
);