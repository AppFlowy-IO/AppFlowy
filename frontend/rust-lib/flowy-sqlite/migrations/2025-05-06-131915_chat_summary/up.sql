-- Your SQL goes here
ALTER TABLE chat_table
    ADD COLUMN summary TEXT NOT NULL DEFAULT '';

ALTER TABLE chat_table DROP COLUMN name;