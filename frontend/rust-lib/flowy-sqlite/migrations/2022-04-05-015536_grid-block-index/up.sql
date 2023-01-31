-- Your SQL goes here
CREATE TABLE grid_block_index_table (
     row_id TEXT NOT NULL PRIMARY KEY,
     block_id TEXT NOT NULL
);

-- CREATE VIRTUAL TABLE grid_block_fts_table USING FTS5(content, grid_id, block_id, row_id);