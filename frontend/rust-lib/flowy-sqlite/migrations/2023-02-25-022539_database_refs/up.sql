-- Your SQL goes here
CREATE TABLE database_refs (
 ref_id TEXT NOT NULL PRIMARY KEY DEFAULT '',
 name TEXT NOT NULL DEFAULT '',
 is_base Boolean NOT NULL DEFAULT false,
 view_id TEXT NOT NULL DEFAULT '',
 database_id TEXT NOT NULL DEFAULT ''
);