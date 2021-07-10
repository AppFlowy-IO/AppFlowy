#[allow(dead_code)]
pub const KV_SQL: &str = r#"
CREATE TABLE IF NOT EXISTS kv_table (
     key TEXT NOT NULL PRIMARY KEY,
     str_value TEXT,
     int_value BIGINT,
     float_value DOUBLE,
     bool_value BOOLEAN
);
"#;

table! {
    kv_table (key) {
        key -> Text,
        str_value -> Nullable<Text>,
        int_value -> Nullable<BigInt>,
        float_value -> Nullable<Double>,
        bool_value -> Nullable<Bool>,
    }
}
