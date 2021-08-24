-- Add migration script here
CREATE TABLE workspace_table(
   id uuid NOT NULL,
   PRIMARY KEY (id),
   name TEXT NOT NULL,
   description TEXT NOT NULL,
   modified_time timestamptz NOT NULL,
   create_time timestamptz NOT NULL,
   user_id TEXT NOT NULL
);