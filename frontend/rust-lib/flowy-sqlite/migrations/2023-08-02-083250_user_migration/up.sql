-- Your SQL goes here
CREATE TABLE user_data_migration_records (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  migration_name TEXT NOT NULL,
  executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);