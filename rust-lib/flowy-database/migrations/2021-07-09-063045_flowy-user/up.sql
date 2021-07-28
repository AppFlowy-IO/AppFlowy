-- Your SQL goes here

CREATE TABLE user_table (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    password TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT ''
);

CREATE TABLE workspace_table (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    desc TEXT NOT NULL DEFAULT '',
    modified_time BIGINT NOT NULL DEFAULT 0,
    create_time BIGINT NOT NULL DEFAULT 0,
    user_id TEXT NOT NULL DEFAULT '',
    version BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE app_table (
    id TEXT NOT NULL PRIMARY KEY,
    workspace_id TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL DEFAULT '',
    desc TEXT NOT NULL DEFAULT '',
    color_style BLOB NOT NULL DEFAULT (x''),
    last_view_id TEXT DEFAULT '',
    modified_time BIGINT NOT NULL DEFAULT 0,
    create_time BIGINT NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE view_table (
    id TEXT NOT NULL PRIMARY KEY,
    belong_to_id TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL DEFAULT '',
    desc TEXT NOT NULL DEFAULT '',
    modified_time BIGINT NOT NULL DEFAULT 0,
    create_time BIGINT NOT NULL DEFAULT 0,
    thumbnail TEXT NOT NULL DEFAULT '',
    view_type INTEGER NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0
);
