use crate::kv::schema::{kv_table, kv_table::dsl, KV_SQL};
use ::diesel::{query_dsl::*, ExpressionMethods};
use diesel::{Connection, SqliteConnection};
use flowy_derive::ProtoBuf;
use flowy_sqlite::{DBConnection, Database, PoolConfig};
use lazy_static::lazy_static;
use std::{path::Path, sync::RwLock};

const DB_NAME: &str = "kv.db";
lazy_static! {
    static ref KV_HOLDER: RwLock<KV> = RwLock::new(KV { database: None });
}

pub struct KV {
    database: Option<Database>,
}

impl KV {
    fn set(item: KeyValue) -> Result<(), String> {
        let _ = diesel::replace_into(kv_table::table)
            .values(&item)
            .execute(&*(get_connection()?))
            .map_err(|e| format!("KV set error: {:?}", e))?;

        Ok(())
    }

    fn get(key: &str) -> Result<KeyValue, String> {
        let conn = get_connection()?;
        let item = dsl::kv_table
            .filter(kv_table::key.eq(key))
            .first::<KeyValue>(&*conn)
            .map_err(|e| format!("KV get error: {:?}", e))?;
        Ok(item)
    }

    #[allow(dead_code)]
    pub fn remove(key: &str) -> Result<(), String> {
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
}

macro_rules! impl_get_func {
    (
        $func_name:ident,
        $get_method:ident=>$target:ident
    ) => {
        impl KV {
            #[allow(dead_code)]
            pub fn $func_name(k: &str) -> Option<$target> {
                match KV::get(k) {
                    Ok(item) => item.$get_method,
                    Err(_) => None,
                }
            }
        }
    };
}

macro_rules! impl_set_func {
    ($func_name:ident,$set_method:ident,$key_type:ident) => {
        impl KV {
            #[allow(dead_code)]
            pub fn $func_name(key: &str, value: $key_type) {
                let mut item = KeyValue::new(key);
                item.$set_method = Some(value);
                match KV::set(item) {
                    Ok(_) => {},
                    Err(e) => {
                        log::error!("{:?}", e)
                    },
                };
            }
        }
    };
}

impl_set_func!(set_str, str_value, String);

impl_set_func!(set_bool, bool_value, bool);

impl_set_func!(set_int, int_value, i64);

impl_set_func!(set_float, float_value, f64);

impl_get_func!(get_str,str_value=>String);

impl_get_func!(get_int,int_value=>i64);

impl_get_func!(get_float,float_value=>f64);

impl_get_func!(get_bool,bool_value=>bool);

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
        },
        Err(e) => {
            let msg = format!("KVStore get connection failed: {:?}", e);
            log::error!("{:?}", msg);
            Err(msg)
        },
    }
}

#[derive(Clone, Debug, ProtoBuf, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[table_name = "kv_table"]
#[primary_key(key)]
pub struct KeyValue {
    #[pb(index = 1)]
    pub key: String,

    #[pb(index = 2, one_of)]
    pub str_value: Option<String>,

    #[pb(index = 3, one_of)]
    pub int_value: Option<i64>,

    #[pb(index = 4, one_of)]
    pub float_value: Option<f64>,

    #[pb(index = 5, one_of)]
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
        assert_eq!(KV::get_bool("1").unwrap(), true);

        assert_eq!(KV::get_bool("2"), None);
    }
}
