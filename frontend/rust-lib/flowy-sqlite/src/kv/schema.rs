#[allow(dead_code)]
pub const KV_SQL: &str = r#"
CREATE TABLE IF NOT EXISTS kv_table (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT
);
"#;

table! {
    kv_table (key) {
        key -> Text,
        value -> Nullable<Text>,
    }
}
