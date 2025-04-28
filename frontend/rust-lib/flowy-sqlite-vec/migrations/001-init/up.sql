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
