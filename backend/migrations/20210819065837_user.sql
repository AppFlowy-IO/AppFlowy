-- Add migration script here
CREATE TABLE user_table(
    id uuid NOT NULL,
    PRIMARY KEY (id),
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    create_time timestamptz NOT NULL,
    password TEXT NOT NULL
);