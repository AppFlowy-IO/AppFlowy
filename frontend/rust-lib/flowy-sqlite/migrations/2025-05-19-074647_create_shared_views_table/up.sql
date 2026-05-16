-- Your SQL goes here
CREATE TABLE IF NOT EXISTS workspace_shared_view (
  uid BigInt NOT NULL,
  workspace_id TEXT NOT NULL,
  view_id TEXT NOT NULL,
  permission_id INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (uid, workspace_id, view_id)
);
