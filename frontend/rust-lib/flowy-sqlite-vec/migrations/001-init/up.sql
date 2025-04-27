CREATE TABLE chunk_embeddings_info
(
    embed_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    fragment_id    TEXT    NOT NULL,
    oid            TEXT    NOT NULL,
    content_type   INTEGER NOT NULL,
    content        TEXT NOT NULL,
    metadata       TEXT,
    fragment_index INTEGER NOT NULL DEFAULT 0,
    embedder_type  INTEGER NOT NULL DEFAULT 0,
    UNIQUE(fragment_id, oid)
);

CREATE INDEX idx_chunk_embeddings_info_oid
    ON chunk_embeddings_info(oid);

create virtual table embeddings_v0 using vec0(
  embedding float[768]
);