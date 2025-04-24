-- Your SQL goes here
ALTER TABLE user_workspace_table
    ADD COLUMN workspace_type INTEGER NOT NULL DEFAULT 1;

-- 2. Back‑fill from user_table.auth_type
UPDATE user_workspace_table
SET workspace_type = (SELECT ut.auth_type
                 FROM user_table ut
                 WHERE ut.id = CAST(user_workspace_table.uid AS TEXT))
WHERE EXISTS (SELECT 1
              FROM user_table ut
              WHERE ut.id = CAST(user_workspace_table.uid AS TEXT));

ALTER TABLE user_table DROP COLUMN stability_ai_key;
ALTER TABLE user_table DROP COLUMN openai_key;
ALTER TABLE user_table DROP COLUMN workspace;
ALTER TABLE user_table DROP COLUMN encryption_type;
ALTER TABLE user_table DROP COLUMN ai_model;

CREATE TABLE workspace_setting_table (
    id TEXT PRIMARY KEY NOT NULL ,
    disable_search_indexing BOOLEAN DEFAULT FALSE NOT NULL ,
    ai_model TEXT DEFAULT "" NOT NULL
);