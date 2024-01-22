-- Your SQL goes here
CREATE VIRTUAL TABLE if not exists search_index USING fts5(index_type, view_id, id, data);