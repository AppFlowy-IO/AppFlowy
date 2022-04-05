use crate::services::persistence::GridDatabase;
use ::diesel::{query_dsl::*, ExpressionMethods};
use bytes::Bytes;
use diesel::SqliteConnection;
use flowy_database::{
    prelude::*,
    schema::{kv_table, kv_table::dsl},
    ConnectionPool,
};
use flowy_error::{FlowyError, FlowyResult};
use std::sync::Arc;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "kv_table"]
#[primary_key(key)]
pub struct KeyValue {
    key: String,
    value: Vec<u8>,
}

pub trait KVTransaction {
    fn get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(&self, key: &str) -> FlowyResult<Option<T>>;
    fn set<T: Into<KeyValue>>(&self, value: T) -> FlowyResult<()>;
    fn remove(&self, key: &str) -> FlowyResult<()>;

    fn batch_get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(&self, keys: Vec<String>)
        -> FlowyResult<Vec<T>>;
    fn batch_set<T: Into<KeyValue>>(&self, values: Vec<T>) -> FlowyResult<()>;
    fn batch_remove(&self, keys: Vec<String>) -> FlowyResult<()>;
}

pub struct GridKVPersistence {
    database: Arc<dyn GridDatabase>,
}

impl GridKVPersistence {
    pub fn new(database: Arc<dyn GridDatabase>) -> Self {
        Self { database }
    }

    pub fn begin_transaction<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: for<'a> FnOnce(SqliteTransaction<'a>) -> FlowyResult<O>,
    {
        let conn = self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let sql_transaction = SqliteTransaction { conn: &conn };
            f(sql_transaction)
        })
    }
}

impl KVTransaction for GridKVPersistence {
    fn get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(&self, key: &str) -> FlowyResult<Option<T>> {
        self.begin_transaction(|transaction| transaction.get(key))
    }

    fn set<T: Into<KeyValue>>(&self, value: T) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.set(value))
    }

    fn remove(&self, key: &str) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.remove(key))
    }

    fn batch_get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(
        &self,
        keys: Vec<String>,
    ) -> FlowyResult<Vec<T>> {
        self.begin_transaction(|transaction| transaction.batch_get(keys))
    }

    fn batch_set<T: Into<KeyValue>>(&self, values: Vec<T>) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.batch_set(values))
    }

    fn batch_remove(&self, keys: Vec<String>) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.batch_remove(keys))
    }
}

pub struct SqliteTransaction<'a> {
    conn: &'a SqliteConnection,
}

impl<'a> KVTransaction for SqliteTransaction<'a> {
    fn get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(&self, key: &str) -> FlowyResult<Option<T>> {
        let item = dsl::kv_table
            .filter(kv_table::key.eq(key))
            .first::<KeyValue>(self.conn)?;
        let value = T::try_from(Bytes::from(item.value)).unwrap();
        Ok(Some(value))
    }

    fn set<T: Into<KeyValue>>(&self, value: T) -> FlowyResult<()> {
        let item: KeyValue = value.into();
        let _ = diesel::replace_into(kv_table::table).values(&item).execute(self.conn)?;
        Ok(())
    }

    fn remove(&self, key: &str) -> FlowyResult<()> {
        let sql = dsl::kv_table.filter(kv_table::key.eq(key));
        let _ = diesel::delete(sql).execute(self.conn)?;
        Ok(())
    }

    fn batch_get<T: TryFrom<Bytes, Error = ::protobuf::ProtobufError>>(
        &self,
        keys: Vec<String>,
    ) -> FlowyResult<Vec<T>> {
        let items = dsl::kv_table
            .filter(kv_table::key.eq_any(&keys))
            .load::<KeyValue>(self.conn)?;
        let mut values = vec![];
        for item in items {
            let value = T::try_from(Bytes::from(item.value)).unwrap();
            values.push(value);
        }
        Ok(values)
    }

    fn batch_set<T: Into<KeyValue>>(&self, values: Vec<T>) -> FlowyResult<()> {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<KeyValue>>();
        let _ = diesel::replace_into(kv_table::table)
            .values(&items)
            .execute(self.conn)?;
        Ok(())
    }

    fn batch_remove(&self, keys: Vec<String>) -> FlowyResult<()> {
        let sql = dsl::kv_table.filter(kv_table::key.eq_any(keys));
        let _ = diesel::delete(sql).execute(self.conn)?;
        Ok(())
    }
}

// impl<T: TryInto<Bytes, Error = ::protobuf::ProtobufError> + GridIdentifiable> std::convert::From<T> for KeyValue {
//     fn from(value: T) -> Self {
//         let key = value.id().to_string();
//         let bytes: Bytes = value.try_into().unwrap();
//         let value = bytes.to_vec();
//         KeyValue { key, value }
//     }
// }
