-- Your SQL goes here
CREATE TABLE index_collab_record_table
(
    oid          TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT             NOT NULL,
    content_hash TEXT             NOT NULL
);

-- create index for workspace_id
CREATE INDEX collab_record_table_workspace_id_idx ON index_collab_record_table (workspace_id);
