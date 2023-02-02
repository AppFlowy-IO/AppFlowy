use crate::kv::schema::{kv_table, kv_table::dsl, KV_SQL};
use crate::sqlite::{DBConnection, Database, PoolConfig};
use ::diesel::{query_dsl::*, ExpressionMethods};
use diesel::{Connection, SqliteConnection};
use lazy_static::lazy_static;
use std::{path::Path, sync::RwLock};

macro_rules! impl_get_func {
    (
        $func_name:ident,
        $get_method:ident=>$target:ident
    ) => {
        #[allow(dead_code)]
        pub fn $func_name(k: &str) -> Option<$target> {
            match KV::get(k) {
                Ok(item) => item.$get_method,
                Err(_) => None,
            }
        }
    };
}

macro_rules! impl_set_func {
    ($func_name:ident,$set_method:ident,$key_type:ident) => {
        #[allow(dead_code)]
        pub fn $func_name(key: &str, value: $key_type) {
            let mut item = KeyValue::new(key);
            item.$set_method = Some(value);
            match KV::set(item) {
                Ok(_) => {}
                Err(e) => {
                    tracing::error!("{:?}", e)
                }
            };
        }
    };
}
const DB_NAME: &str = "kv.db";
lazy_static! {
    static ref KV_HOLDER: RwLock<KV> = RwLock::new(KV::new());
}

pub struct KV {
    database: Option<Database>,
}

impl KV {
    fn new() -> Self {
        KV { database: None }
    }

    fn set(value: KeyValue) -> Result<(), String> {
        // tracing::trace!("[KV]: set value: {:?}", value);
        let _ = diesel::replace_into(kv_table::table)
            .values(&value)
            .execute(&*(get_connection()?))
            .map_err(|e| format!("KV set error: {:?}", e))?;

        Ok(())
    }

    fn get(key: &str) -> Result<KeyValue, String> {
        let conn = get_connection()?;
        let value = dsl::kv_table
            .filter(kv_table::key.eq(key))
            .first::<KeyValue>(&*conn)
            .map_err(|e| format!("KV get error: {:?}", e))?;

        Ok(value)
    }

    #[allow(dead_code)]
    pub fn remove(key: &str) -> Result<(), String> {
        // tracing::debug!("remove key: {}", key);
        let conn = get_connection()?;
        let sql = dsl::kv_table.filter(kv_table::key.eq(key));
        let _ = diesel::delete(sql)
            .execute(&*conn)
            .map_err(|e| format!("KV remove error: {:?}", e))?;
        Ok(())
    }

    #[tracing::instrument(level = "trace", err)]
    pub fn init(root: &str) -> Result<(), String> {
        if !Path::new(root).exists() {
            return Err(format!("Init KVStore failed. {} not exists", root));
        }

        let pool_config = PoolConfig::default();
        let database = Database::new(root, DB_NAME, pool_config).unwrap();
        let conn = database.get_connection().unwrap();
        SqliteConnection::execute(&*conn, KV_SQL).unwrap();

        let mut store = KV_HOLDER
            .write()
            .map_err(|e| format!("KVStore write failed: {:?}", e))?;
        tracing::trace!("Init kv with path: {}", root);
        store.database = Some(database);

        Ok(())
    }

    pub fn get_bool(key: &str) -> bool {
        match KV::get(key) {
            Ok(item) => item.bool_value.unwrap_or(false),
            Err(_) => false,
        }
    }

    impl_set_func!(set_str, str_value, String);

    impl_set_func!(set_bool, bool_value, bool);

    impl_set_func!(set_int, int_value, i64);

    impl_set_func!(set_float, float_value, f64);

    impl_get_func!(get_str,str_value=>String);

    impl_get_func!(get_int,int_value=>i64);

    impl_get_func!(get_float,float_value=>f64);
}

fn get_connection() -> Result<DBConnection, String> {
    match KV_HOLDER.read() {
        Ok(store) => {
            let conn = store
                .database
                .as_ref()
                .expect("KVStore is not init")
                .get_connection()
                .map_err(|e| format!("KVStore error: {:?}", e))?;
            Ok(conn)
        }
        Err(e) => {
            let msg = format!("KVStore get connection failed: {:?}", e);
            tracing::error!("{:?}", msg);
            Err(msg)
        }
    }
}

#[derive(Clone, Debug, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[table_name = "kv_table"]
#[primary_key(key)]
pub struct KeyValue {
    pub key: String,
    pub str_value: Option<String>,
    pub int_value: Option<i64>,
    pub float_value: Option<f64>,
    pub bool_value: Option<bool>,
}

impl KeyValue {
    pub fn new(key: &str) -> Self {
        KeyValue {
            key: key.to_string(),
            ..Default::default()
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::kv::KV;

    #[test]
    fn kv_store_test() {
        let dir = "./temp/";
        if !std::path::Path::new(dir).exists() {
            std::fs::create_dir_all(dir).unwrap();
        }

        KV::init(dir).unwrap();

        KV::set_str("1", "hello".to_string());
        assert_eq!(KV::get_str("1").unwrap(), "hello");

        assert_eq!(KV::get_str("2"), None);

        KV::set_bool("1", true);
        assert!(KV::get_bool("1"));

        assert!(!KV::get_bool("2"));
    }
}
