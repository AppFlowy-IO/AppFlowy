CREATE VIRTUAL TABLE af_collab_embeddings 
USING vec0(
  workspace_id    TEXT    NOT NULL,
  object_id       TEXT    NOT NULL,
  fragment_id     TEXT    NOT NULL,
  content_type    INTEGER NOT NULL,
  content         TEXT    NOT NULL,
  metadata        TEXT,
  fragment_index  INTEGER NOT NULL DEFAULT 0,
  embedder_type   INTEGER NOT NULL DEFAULT 0,
  embedding       float[768] 
);

CREATE TABLE af_pending_index_collab
(
    oid          TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT             NOT NULL,
    content      TEXT             NOT NULL,
    collab_type  SMALLINT         NOT NULL,
    updated_at   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    indexed_at   TIMESTAMP                 DEFAULT NULL
);

-- create index for oid and workspace_id
CREATE INDEX collab_table_oid_workspace_id_idx ON af_pending_index_collab (oid, workspace_id);
