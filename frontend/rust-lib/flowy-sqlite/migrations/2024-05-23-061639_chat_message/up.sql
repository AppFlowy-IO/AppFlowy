-- Your SQL goes here
-- Create table for chat documents
CREATE TABLE chat_table
(
    chat_id    TEXT PRIMARY KEY NOT NULL,
    created_at BIGINT           NOT NULL,
    name       TEXT             NOT NULL DEFAULT ''
);

-- Create table for chat messages
CREATE TABLE chat_message_table
(
    message_id  BIGINT PRIMARY KEY NOT NULL,
    chat_id     TEXT               NOT NULL,
    content     TEXT               NOT NULL,
    created_at  BIGINT             NOT NULL,
    author_type BIGINT             NOT NULL,
    author_id   TEXT               NOT NULL,
    FOREIGN KEY (chat_id) REFERENCES chat_table (chat_id) ON DELETE CASCADE
);

CREATE INDEX idx_chat_messages_chat_id_created_at ON chat_message_table (message_id ASC, created_at ASC);
