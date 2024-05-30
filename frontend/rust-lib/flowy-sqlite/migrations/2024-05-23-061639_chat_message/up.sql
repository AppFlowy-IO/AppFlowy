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
    message_id       BIGINT PRIMARY KEY NOT NULL,
    chat_id          TEXT               NOT NULL,
    content          TEXT               NOT NULL,
    created_at       BIGINT             NOT NULL,
    author_type      BIGINT             NOT NULL,
    author_id        TEXT               NOT NULL,
    reply_message_id BIGINT
);
CREATE INDEX idx_chat_messages_chat_id_message_id ON chat_message_table (chat_id, message_id);
