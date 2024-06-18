-- Your SQL goes here
CREATE TABLE upload_file_table (
    workspace_id TEXT NOT NULL,
    file_id TEXT NOT NULL,
    parent_dir TEXT NOT NULL,
    local_file_path TEXT NOT NULL,
    content_type TEXT NOT NULL,
    chunk_size INTEGER NOT NULL,
    num_chunk INTEGER NOT NULL,
    upload_id TEXT NOT NULL DEFAULT '',
    created_at BIGINT NOT NULL,
    PRIMARY KEY (workspace_id, parent_dir, file_id)
);

CREATE TABLE upload_file_part (
    upload_id TEXT NOT NULL,
    e_tag TEXT NOT NULL,
    part_num INTEGER NOT NULL,
    PRIMARY KEY (upload_id, e_tag)
);