-- Your SQL goes here
CREATE TABLE IF NOT EXISTS workspace_shared_user (
  workspace_id TEXT NOT NULL,
  view_id TEXT NOT NULL,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT NOT NULL,
  role INTEGER NOT NULL,
  access_level INTEGER NOT NULL,
  PRIMARY KEY (workspace_id, view_id, email)
);
