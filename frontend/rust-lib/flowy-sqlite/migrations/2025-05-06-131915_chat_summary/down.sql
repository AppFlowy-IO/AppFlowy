-- This file should undo anything in `up.sql`
ALTER TABLE chat_table
    ADD COLUMN summary TEXT;
