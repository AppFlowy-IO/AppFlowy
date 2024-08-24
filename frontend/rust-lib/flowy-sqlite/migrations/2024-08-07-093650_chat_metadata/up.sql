-- Your SQL goes here
ALTER TABLE chat_table RENAME COLUMN local_model_path TO local_files;
ALTER TABLE chat_table RENAME COLUMN local_model_name TO metadata;

