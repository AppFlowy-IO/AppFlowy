use crate::{
    services::kv::{KVTransaction, KeyValue},
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use anyhow::Context;
use async_trait::async_trait;
use backend_service::errors::ServerError;
use bytes::Bytes;

use lib_infra::future::BoxResultFuture;
use sql_builder::SqlBuilder as RawSqlBuilder;
use sqlx::{
    postgres::{PgArguments, PgRow},
    Arguments,
    Error,
    PgPool,
    Postgres,
    Row,
};

const KV_TABLE: &str = "kv_table";

pub struct PostgresKV {
    pub(crate) pg_pool: PgPool,
}

impl PostgresKV {
    pub async fn get(&self, key: &str) -> Result<Option<Bytes>, ServerError> {
        let key = key.to_owned();
        self.transaction(|mut transaction| Box::pin(async move { transaction.get(&key).await }))
            .await
    }
    pub async fn set(&self, key: &str, value: Bytes) -> Result<(), ServerError> {
        let key = key.to_owned();
        self.transaction(|mut transaction| Box::pin(async move { transaction.set(&key, value).await }))
            .await
    }

    pub async fn remove(&self, key: &str) -> Result<(), ServerError> {
        let key = key.to_owned();
        self.transaction(|mut transaction| Box::pin(async move { transaction.remove(&key).await }))
            .await
    }

    pub async fn batch_set(&self, kvs: Vec<KeyValue>) -> Result<(), ServerError> {
        self.transaction(|mut transaction| Box::pin(async move { transaction.batch_set(kvs).await }))
            .await
    }

    pub async fn batch_get(&self, keys: Vec<String>) -> Result<Vec<KeyValue>, ServerError> {
        self.transaction(|mut transaction| Box::pin(async move { transaction.batch_get(keys).await }))
            .await
    }

    pub async fn transaction<F, O>(&self, f: F) -> Result<O, ServerError>
    where
        F: for<'a> FnOnce(Box<dyn KVTransaction + 'a>) -> BoxResultFuture<O, ServerError>,
    {
        let mut transaction = self
            .pg_pool
            .begin()
            .await
            .context("[KV]:Failed to acquire a Postgres connection")?;
        let postgres_transaction = PostgresTransaction(&mut transaction);
        let result = f(Box::new(postgres_transaction)).await;
        transaction
            .commit()
            .await
            .context("[KV]:Failed to commit SQL transaction.")?;

        result
    }
}

pub(crate) struct PostgresTransaction<'a, 'b>(&'a mut DBTransaction<'b>);

#[async_trait]
impl<'a, 'b> KVTransaction for PostgresTransaction<'a, 'b> {
    async fn get(&mut self, key: &str) -> Result<Option<Bytes>, ServerError> {
        let id = key.to_string();
        let (sql, args) = SqlBuilder::select(KV_TABLE)
            .add_field("*")
            .and_where_eq("id", &id)
            .build()?;

        let result = sqlx::query_as_with::<Postgres, KVTable, PgArguments>(&sql, args)
            .fetch_one(self.0 as &mut DBTransaction<'b>)
            .await;

        match result {
            Ok(val) => Ok(Some(Bytes::from(val.blob))),
            Err(error) => match error {
                Error::RowNotFound => Ok(None),
                _ => Err(map_sqlx_error(error)),
            },
        }
    }

    async fn set(&mut self, key: &str, bytes: Bytes) -> Result<(), ServerError> {
        self.batch_set(vec![KeyValue {
            key: key.to_string(),
            value: bytes,
        }])
        .await
    }

    async fn remove(&mut self, key: &str) -> Result<(), ServerError> {
        let id = key.to_string();
        let (sql, args) = SqlBuilder::delete(KV_TABLE).and_where_eq("id", &id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
        Ok(())
    }

    async fn batch_set(&mut self, kvs: Vec<KeyValue>) -> Result<(), ServerError> {
        let mut builder = RawSqlBuilder::insert_into(KV_TABLE);
        let m_builder = builder.field("id").field("blob");

        let mut args = PgArguments::default();
        kvs.iter().enumerate().for_each(|(index, _)| {
            let index = index * 2 + 1;
            m_builder.values(&[format!("${}", index), format!("${}", index + 1)]);
        });

        for kv in kvs {
            args.add(kv.key);
            args.add(kv.value.to_vec());
        }

        let sql = m_builder.sql()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        Ok::<(), ServerError>(())
    }

    async fn batch_get(&mut self, keys: Vec<String>) -> Result<Vec<KeyValue>, ServerError> {
        let sql = RawSqlBuilder::select_from(KV_TABLE)
            .field("id")
            .field("blob")
            .and_where_in_quoted("id", &keys)
            .sql()?;

        let rows = sqlx::query(&sql)
            .fetch_all(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
        let kvs = rows_to_key_values(rows);
        Ok::<Vec<KeyValue>, ServerError>(kvs)
    }

    async fn batch_delete(&mut self, keys: Vec<String>) -> Result<(), ServerError> {
        let sql = RawSqlBuilder::delete_from(KV_TABLE).and_where_in("id", &keys).sql()?;
        let _ = sqlx::query(&sql)
            .execute(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        Ok::<(), ServerError>(())
    }

    async fn batch_get_start_with(&mut self, key: &str) -> Result<Vec<KeyValue>, ServerError> {
        let prefix = key.to_owned();
        let sql = RawSqlBuilder::select_from(KV_TABLE)
            .field("id")
            .field("blob")
            .and_where_like_left("id", &prefix)
            .sql()?;

        let rows = sqlx::query(&sql)
            .fetch_all(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        let kvs = rows_to_key_values(rows);

        Ok::<Vec<KeyValue>, ServerError>(kvs)
    }

    async fn batch_delete_key_start_with(&mut self, keyword: &str) -> Result<(), ServerError> {
        let keyword = keyword.to_owned();
        let sql = RawSqlBuilder::delete_from(KV_TABLE)
            .and_where_like_left("id", &keyword)
            .sql()?;

        let _ = sqlx::query(&sql)
            .execute(self.0 as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
        Ok::<(), ServerError>(())
    }
}
fn rows_to_key_values(rows: Vec<PgRow>) -> Vec<KeyValue> {
    rows.into_iter()
        .map(|row| {
            let bytes: Vec<u8> = row.get("blob");
            KeyValue {
                key: row.get("id"),
                value: Bytes::from(bytes),
            }
        })
        .collect::<Vec<KeyValue>>()
}

#[derive(Debug, Clone, sqlx::FromRow)]
struct KVTable {
    pub(crate) id: String,
    pub(crate) blob: Vec<u8>,
}
