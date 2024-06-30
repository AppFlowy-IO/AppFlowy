use std::path::Path;

use ::diesel::{query_dsl::*, ExpressionMethods};
use anyhow::anyhow;
use diesel::sql_query;
use serde::de::DeserializeOwned;
use serde::Serialize;

use crate::kv::schema::{kv_table, kv_table::dsl, KV_SQL};
use crate::sqlite_impl::{Database, PoolConfig};

const DB_NAME: &str = "cache.db";

/// [KVStorePreferences] uses a sqlite database to store key value pairs.
/// Most of the time, it used to storage AppFlowy configuration.
#[derive(Clone)]
pub struct KVStorePreferences {
  database: Option<Database>,
}
impl KVStorePreferences {
  #[tracing::instrument(level = "trace", err)]
  pub fn new(root: &str) -> Result<Self, anyhow::Error> {
    if !Path::new(root).exists() {
      return Err(anyhow!("Init StorePreferences failed. {} not exists", root));
    }

    let pool_config = PoolConfig::default();
    let database = Database::new(root, DB_NAME, pool_config).unwrap();
    let mut conn = database.get_connection().unwrap();
    sql_query(KV_SQL).execute(&mut conn).unwrap();

    tracing::trace!("Init StorePreferences with path: {}", root);
    Ok(Self {
      database: Some(database),
    })
  }

  /// Set a string value of a key
  pub fn set_str<T: ToString>(&self, key: &str, value: T) {
    let _ = self.set_key_value(key, Some(value.to_string()));
  }

  /// Set a bool value of a key
  pub fn set_bool(&self, key: &str, value: bool) -> Result<(), anyhow::Error> {
    self.set_key_value(key, Some(value.to_string()))
  }

  /// Set a object that implements [Serialize] trait of a key
  pub fn set_object<T: Serialize>(&self, key: &str, value: T) -> Result<(), anyhow::Error> {
    let value = serde_json::to_string(&value)?;
    self.set_key_value(key, Some(value))?;
    Ok(())
  }

  /// Set a i64 value of a key
  pub fn set_i64(&self, key: &str, value: i64) -> Result<(), anyhow::Error> {
    self.set_key_value(key, Some(value.to_string()))
  }

  /// Get a string value of a key
  pub fn get_str(&self, key: &str) -> Option<String> {
    self.get_key_value(key).and_then(|kv| kv.value)
  }

  /// Get a bool value of a key
  pub fn get_bool(&self, key: &str) -> bool {
    self
      .get_key_value(key)
      .and_then(|kv| kv.value)
      .and_then(|v| v.parse::<bool>().ok())
      .unwrap_or(false)
  }

  /// Get a i64 value of a key
  pub fn get_i64(&self, key: &str) -> Option<i64> {
    self
      .get_key_value(key)
      .and_then(|kv| kv.value)
      .and_then(|v| v.parse::<i64>().ok())
  }

  /// Get a object that implements [DeserializeOwned] trait of a key
  pub fn get_object<T: DeserializeOwned>(&self, key: &str) -> Option<T> {
    self
      .get_str(key)
      .and_then(|v| serde_json::from_str(&v).ok())
  }

  pub fn remove(&self, key: &str) {
    if let Some(mut conn) = self
      .database
      .as_ref()
      .and_then(|database| database.get_connection().ok())
    {
      let sql = dsl::kv_table.filter(kv_table::key.eq(key));
      let _ = diesel::delete(sql).execute(&mut *conn);
    }
  }

  fn set_key_value(&self, key: &str, value: Option<String>) -> Result<(), anyhow::Error> {
    match self
      .database
      .as_ref()
      .and_then(|database| database.get_connection().ok())
    {
      None => Err(anyhow!("StorePreferences is not initialized")),
      Some(mut conn) => {
        diesel::replace_into(kv_table::table)
          .values(KeyValue {
            key: key.to_string(),
            value,
          })
          .execute(&mut *conn)?;
        Ok(())
      },
    }
  }

  fn get_key_value(&self, key: &str) -> Option<KeyValue> {
    let mut conn = self.database.as_ref().unwrap().get_connection().ok()?;
    dsl::kv_table
      .filter(kv_table::key.eq(key))
      .first::<KeyValue>(&mut *conn)
      .ok()
  }
}

#[derive(Clone, Debug, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[diesel(table_name = kv_table)]
#[diesel(primary_key(key))]
pub struct KeyValue {
  pub key: String,
  pub value: Option<String>,
}

#[cfg(test)]
mod tests {
  use serde::{Deserialize, Serialize};
  use tempfile::TempDir;

  use crate::kv::KVStorePreferences;

  #[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Debug)]
  struct Person {
    name: String,
    age: i32,
  }

  #[test]
  fn kv_store_test() {
    let tempdir = TempDir::new().unwrap();
    let path = tempdir.into_path();
    let store = KVStorePreferences::new(path.to_str().unwrap()).unwrap();

    store.set_str("1", "hello".to_string());
    assert_eq!(store.get_str("1").unwrap(), "hello");
    assert_eq!(store.get_str("2"), None);

    store.set_bool("1", true).unwrap();
    assert!(store.get_bool("1"));
    assert!(!store.get_bool("2"));

    store.set_i64("1", 1).unwrap();
    assert_eq!(store.get_i64("1").unwrap(), 1);
    assert_eq!(store.get_i64("2"), None);

    let person = Person {
      name: "nathan".to_string(),
      age: 30,
    };
    store.set_object("1", person.clone()).unwrap();
    assert_eq!(store.get_object::<Person>("1").unwrap(), person);
  }
}
