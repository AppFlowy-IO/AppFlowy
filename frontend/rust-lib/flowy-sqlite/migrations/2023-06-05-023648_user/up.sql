-- Your SQL goes here
CREATE TABLE user_table (
 id TEXT NOT NULL PRIMARY KEY,
 name TEXT NOT NULL DEFAULT '',
 workspace TEXT NOT NULL DEFAULT '',
 icon_url TEXT NOT NULL DEFAULT '',
 openai_key TEXT NOT NULL DEFAULT '',
 token TEXT NOT NULL DEFAULT '',
 email TEXT NOT NULL DEFAULT ''
);
