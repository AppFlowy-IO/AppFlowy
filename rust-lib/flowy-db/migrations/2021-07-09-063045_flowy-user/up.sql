-- Your SQL goes here

CREATE TABLE user_table (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        password TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT ''
);
