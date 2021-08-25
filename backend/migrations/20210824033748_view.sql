-- Add migration script here
CREATE TABLE IF NOT EXISTS view_table(
      id uuid NOT NULL,
      PRIMARY KEY (id),
      belong_to_id TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      modified_time timestamptz NOT NULL,
      create_time timestamptz NOT NULL,
      thumbnail TEXT NOT NULL,
      view_type INTEGER NOT NULL,
      is_trash BOOL NOT NULL DEFAULT false
);