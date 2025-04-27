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

