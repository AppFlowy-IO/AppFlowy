-- Your SQL goes here
ALTER TABLE workspace_members_table
    ADD COLUMN joined_at BIGINT DEFAULT NULL;
