use std::path::Path;

use ::diesel::{query_dsl::*, ExpressionMethods};
use anyhow::anyhow;
use diesel::{Connection, SqliteConnection};
use lazy_static::lazy_static;
use parking_lot::RwLock;
use serde::de::DeserializeOwned;
use serde::Serialize;

use crate::kv::schema::{kv_table, kv_table::dsl, KV_SQL};
use crate::sqlite::{DBConnection, Database, PoolConfig};

const DB_NAME: &str = "cache.db";
lazy_static! {
  static ref KV_HOLDER: RwLock<KV> = RwLock::new(KV::new());
}

/// [KV] uses a sqlite database to store key value pairs.
/// Most of the time, it used to storage AppFlowy configuration.
pub struct KV {
  database: Option<Database>,
}

impl KV {
  fn new() -> Self {
    KV { database: None }
  }

  #[tracing::instrument(level = "trace", err)]
  pub fn init(root: &str) -> Result<(), anyhow::Error> {
    if !Path::new(root).exists() {
      return Err(anyhow!("Init KV failed. {} not exists", root));
    }

    let pool_config = PoolConfig::default();
    let database = Database::new(root, DB_NAME, pool_config).unwrap();
    let conn = database.get_connection().unwrap();
    SqliteConnection::execute(&*conn, KV_SQL).unwrap();

    tracing::trace!("Init kv with path: {}", root);
    KV_HOLDER.write().database = Some(database);

    Ok(())
  }

  /// Set a string value of a key
  pub fn set_str<T: ToString>(key: &str, value: T) {
    let _ = Self::set_key_value(key, Some(value.to_string()));
  }

  /// Set a bool value of a key
  pub fn set_bool(key: &str, value: bool) -> Result<(), anyhow::Error> {
    Self::set_key_value(key, Some(value.to_string()))
  }

  /// Set a object that implements [Serialize] trait of a key
  pub fn set_object<T: Serialize>(key: &str, value: T) -> Result<(), anyhow::Error> {
    let value = serde_json::to_string(&value)?;
    Self::set_key_value(key, Some(value))?;
    Ok(())
  }

  /// Set a i64 value of a key
  pub fn set_i64(key: &str, value: i64) -> Result<(), anyhow::Error> {
    Self::set_key_value(key, Some(value.to_string()))
  }

  /// Get a string value of a key
  pub fn get_str(key: &str) -> Option<String> {
    Self::get_key_value(key).and_then(|kv| kv.value)
  }

  /// Get a bool value of a key
  pub fn get_bool(key: &str) -> bool {
    Self::get_key_value(key)
      .and_then(|kv| kv.value)
      .and_then(|v| v.parse::<bool>().ok())
      .unwrap_or(false)
  }

  /// Get a i64 value of a key
  pub fn get_i64(key: &str) -> Option<i64> {
    Self::get_key_value(key)
      .and_then(|kv| kv.value)
      .and_then(|v| v.parse::<i64>().ok())
  }

  /// Get a object that implements [DeserializeOwned] trait of a key
  pub fn get_object<T: DeserializeOwned>(key: &str) -> Option<T> {
    Self::get_str(key).and_then(|v| serde_json::from_str(&v).ok())
  }

  #[allow(dead_code)]
  pub fn remove(key: &str) {
    if let Ok(conn) = get_connection() {
      let sql = dsl::kv_table.filter(kv_table::key.eq(key));
      let _ = diesel::delete(sql).execute(&*conn);
    }
  }

  fn set_key_value(key: &str, value: Option<String>) -> Result<(), anyhow::Error> {
    let conn = get_connection()?;
    diesel::replace_into(kv_table::table)
      .values(KeyValue {
        key: key.to_string(),
        value,
      })
      .execute(&*conn)?;
    Ok(())
  }

  fn get_key_value(key: &str) -> Option<KeyValue> {
    let conn = get_connection().ok()?;
    dsl::kv_table
      .filter(kv_table::key.eq(key))
      .first::<KeyValue>(&*conn)
      .ok()
  }
}

fn get_connection() -> Result<DBConnection, anyhow::Error> {
  let conn = KV_HOLDER
    .read()
    .database
    .as_ref()
    .expect("KVStore is not init")
    .get_connection()
    .map_err(|_e| anyhow!("Get KV connection error"))?;
  Ok(conn)
}

#[derive(Clone, Debug, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[table_name = "kv_table"]
#[primary_key(key)]
pub struct KeyValue {
  pub key: String,
  pub value: Option<String>,
}

#[cfg(test)]
mod tests {
  use serde::{Deserialize, Serialize};
  use tempfile::TempDir;

  use crate::kv::KV;

  #[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Debug)]
  struct Person {
    name: String,
    age: i32,
  }

  #[test]
  fn kv_store_test() {
    let tempdir = TempDir::new().unwrap();
    let path = tempdir.into_path();
    KV::init(path.to_str().unwrap()).unwrap();

    KV::set_str("1", "hello".to_string());
    assert_eq!(KV::get_str("1").unwrap(), "hello");
    assert_eq!(KV::get_str("2"), None);

    KV::set_bool("1", true).unwrap();
    assert!(KV::get_bool("1"));
    assert!(!KV::get_bool("2"));

    KV::set_i64("1", 1).unwrap();
    assert_eq!(KV::get_i64("1").unwrap(), 1);
    assert_eq!(KV::get_i64("2"), None);

    let person = Person {
      name: "nathan".to_string(),
      age: 30,
    };
    KV::set_object("1", person.clone()).unwrap();
    assert_eq!(KV::get_object::<Person>("1").unwrap(), person);
  }
}
