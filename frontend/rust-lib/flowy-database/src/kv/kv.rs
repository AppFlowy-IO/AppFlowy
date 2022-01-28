use crate::kv::schema::{kv_table, kv_table::dsl, KV_SQL};
use ::diesel::{query_dsl::*, ExpressionMethods};
use diesel::{Connection, SqliteConnection};
use lazy_static::lazy_static;
use lib_sqlite::{DBConnection, Database, PoolConfig};
use std::{collections::HashMap, path::Path, sync::RwLock};

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
                    log::error!("{:?}", e)
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
    cache: HashMap<String, KeyValue>,
}

impl KV {
    fn new() -> Self {
        KV {
            database: None,
            cache: HashMap::new(),
        }
    }

    fn set(value: KeyValue) -> Result<(), String> {
        log::trace!("[KV]: set value: {:?}", value);
        update_cache(value.clone());

        let _ = diesel::replace_into(kv_table::table)
            .values(&value)
            .execute(&*(get_connection()?))
            .map_err(|e| format!("KV set error: {:?}", e))?;

        Ok(())
    }

    fn get(key: &str) -> Result<KeyValue, String> {
        if let Some(value) = read_cache(key) {
            return Ok(value);
        }

        let conn = get_connection()?;
        let value = dsl::kv_table
            .filter(kv_table::key.eq(key))
            .first::<KeyValue>(&*conn)
            .map_err(|e| format!("KV get error: {:?}", e))?;

        update_cache(value.clone());

        Ok(value)
    }

    #[allow(dead_code)]
    pub fn remove(key: &str) -> Result<(), String> {
        log::debug!("remove key: {}", key);
        match KV_HOLDER.write() {
            Ok(mut guard) => {
                guard.cache.remove(key);
            }
            Err(e) => log::error!("Require write lock failed: {:?}", e),
        };

        let conn = get_connection()?;
        let sql = dsl::kv_table.filter(kv_table::key.eq(key));
        let _ = diesel::delete(sql)
            .execute(&*conn)
            .map_err(|e| format!("KV remove error: {:?}", e))?;
        Ok(())
    }

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

fn read_cache(key: &str) -> Option<KeyValue> {
    match KV_HOLDER.read() {
        Ok(guard) => guard.cache.get(key).cloned(),
        Err(e) => {
            log::error!("Require read lock failed: {:?}", e);
            None
        }
    }
}

fn update_cache(value: KeyValue) {
    match KV_HOLDER.write() {
        Ok(mut guard) => {
            guard.cache.insert(value.key.clone(), value);
        }
        Err(e) => log::error!("Require write lock failed: {:?}", e),
    };
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
            log::error!("{:?}", msg);
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
