-- Your SQL goes here
CREATE TABLE af_collab_metadata (
    object_id TEXT PRIMARY KEY NOT NULL,
    updated_at BIGINT NOT NULL,
    prev_sync_state_vector BLOB NOT NULL,
    collab_type INTEGER NOT NULL
);