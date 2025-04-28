-- Your SQL goes here
CREATE TABLE collab_table
(
    oid          TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT             NOT NULL,
    content      TEXT             NOT NULL,
    collab_type  SMALLINT         NOT NULL,
    updated_at   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    indexed_at   TIMESTAMP                 DEFAULT NULL,
    deleted_at   TIMESTAMP                 DEFAULT NULL
);

-- create index for oid and workspace_id
CREATE INDEX collab_table_oid_workspace_id_idx ON collab_table (oid, workspace_id);
