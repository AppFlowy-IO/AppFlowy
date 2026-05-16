-- This file should undo anything in `up.sql`

-- SQLite does not support DROP COLUMN directly, so we recreate the table without the 'order' column
PRAGMA foreign_keys=off;

CREATE TABLE IF NOT EXISTS workspace_shared_user_temp (
  workspace_id TEXT NOT NULL,
  view_id TEXT NOT NULL,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT NOT NULL,
  role INTEGER NOT NULL,
  access_level INTEGER NOT NULL,
  PRIMARY KEY (workspace_id, view_id, email)
);

INSERT INTO workspace_shared_user_temp (workspace_id, view_id, email, name, avatar_url, role, access_level)
SELECT workspace_id, view_id, email, name, avatar_url, role, access_level
FROM workspace_shared_user;

DROP TABLE workspace_shared_user;
ALTER TABLE workspace_shared_user_temp RENAME TO workspace_shared_user;

PRAGMA foreign_keys=on;
