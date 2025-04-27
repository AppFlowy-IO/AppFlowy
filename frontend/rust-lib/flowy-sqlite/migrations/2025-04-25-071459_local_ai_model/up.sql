-- Your SQL goes here
CREATE TABLE local_ai_model_table
(
    name       TEXT PRIMARY KEY NOT NULL,
    model_type SMALLINT         NOT NULL
);

CREATE TABLE collab_table
(
    oid         TEXT PRIMARY KEY NOT NULL,
    content     TEXT             NOT NULL,
    collab_type SMALLINT         NOT NULL,
    updated_at  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    indexed_at  TIMESTAMP                 DEFAULT NULL,
    deleted_at  TIMESTAMP                 DEFAULT NULL
);

CREATE TABLE collab_embeddings_table
(
    fragment_id    TEXT    NOT NULL,
    oid            TEXT    NOT NULL,
    faiss_id       BIGINT  NOT NULL,
    content_type   INTEGER NOT NULL,
    content        TEXT,
    metadata       TEXT,
    fragment_index INTEGER NOT NULL DEFAULT 0,
    embedder_type  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (fragment_id, oid),
    FOREIGN KEY (oid)
        REFERENCES collab_table (oid)
        ON DELETE CASCADE
);

CREATE INDEX ix_af_collab_embeddings_oid
    ON collab_embeddings_table (oid);

CREATE INDEX ix_af_collab_embeddings_faiss_id
    ON collab_embeddings_table (faiss_id);
