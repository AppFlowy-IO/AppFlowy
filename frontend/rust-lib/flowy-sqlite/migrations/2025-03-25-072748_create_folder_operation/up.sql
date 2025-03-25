-- Your SQL goes here
CREATE TABLE folder_operation_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workspace_id TEXT NOT NULL,
    page_id TEXT,
    name TEXT NOT NULL,
    method TEXT NOT NULL,
    status TEXT NOT NULL,
    payload TEXT NOT NULL,
    timestamp TEXT NOT NULL
);