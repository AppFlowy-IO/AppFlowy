use crate::{
    services::kv::{KVAction, KVStore, KeyValue},
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use anyhow::Context;
use async_trait::async_trait;
use backend_service::errors::ServerError;
use bytes::Bytes;
use futures_core::future::BoxFuture;
use lib_infra::future::{BoxResultFuture, FutureResultSend};
use sql_builder::SqlBuilder as RawSqlBuilder;
use sqlx::{
    postgres::{PgArguments, PgRow},
    Arguments,
    Error,
    PgPool,
    Postgres,
    Row,
};
use std::{future::Future, pin::Pin};

const KV_TABLE: &str = "kv_table";

pub(crate) struct PostgresKV {
    pub(crate) pg_pool: PgPool,
}

impl PostgresKV {
    async fn transaction<F, O>(&self, f: F) -> Result<O, ServerError>
    where
        F: for<'a> FnOnce(&'a mut DBTransaction<'_>) -> BoxFuture<'a, Result<O, ServerError>>,
    {
        let mut transaction = self
            .pg_pool
            .begin()
            .await
            .context("[KV]:Failed to acquire a Postgres connection")?;

        let result = f(&mut transaction).await;

        transaction
            .commit()
            .await
            .context("[KV]:Failed to commit SQL transaction.")?;

        result
    }
}

impl KVStore for PostgresKV {}

pub(crate) struct PostgresTransaction<'a> {
    pub(crate) transaction: DBTransaction<'a>,
}

impl<'a> PostgresTransaction<'a> {}

#[async_trait]
impl KVAction for PostgresKV {
    async fn get(&self, key: &str) -> Result<Option<Bytes>, ServerError> {
        let id = key.to_string();
        self.transaction(|transaction| {
            Box::pin(async move {
                let (sql, args) = SqlBuilder::select(KV_TABLE)
                    .add_field("*")
                    .and_where_eq("id", &id)
                    .build()?;

                let result = sqlx::query_as_with::<Postgres, KVTable, PgArguments>(&sql, args)
                    .fetch_one(transaction)
                    .await;

                let result = match result {
                    Ok(val) => Ok(Some(Bytes::from(val.blob))),
                    Err(error) => match error {
                        Error::RowNotFound => Ok(None),
                        _ => Err(map_sqlx_error(error)),
                    },
                };
                result
            })
        })
        .await
    }

    async fn set(&self, key: &str, bytes: Bytes) -> Result<(), ServerError> {
        self.batch_set(vec![KeyValue {
            key: key.to_string(),
            value: bytes,
        }])
        .await
    }

    async fn remove(&self, key: &str) -> Result<(), ServerError> {
        let id = key.to_string();
        self.transaction(|transaction| {
            Box::pin(async move {
                let (sql, args) = SqlBuilder::delete(KV_TABLE).and_where_eq("id", &id).build()?;
                let _ = sqlx::query_with(&sql, args)
                    .execute(transaction)
                    .await
                    .map_err(map_sqlx_error)?;
                Ok(())
            })
        })
        .await
    }

    async fn batch_set(&self, kvs: Vec<KeyValue>) -> Result<(), ServerError> {
        self.transaction(|transaction| {
            Box::pin(async move {
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
                    .execute(transaction)
                    .await
                    .map_err(map_sqlx_error)?;

                Ok::<(), ServerError>(())
            })
        })
        .await
    }

    async fn batch_get(&self, keys: Vec<String>) -> Result<Vec<KeyValue>, ServerError> {
        self.transaction(|transaction| {
            Box::pin(async move {
                let sql = RawSqlBuilder::select_from(KV_TABLE)
                    .field("id")
                    .field("blob")
                    .and_where_in_quoted("id", &keys)
                    .sql()?;

                let rows = sqlx::query(&sql).fetch_all(transaction).await.map_err(map_sqlx_error)?;
                let kvs = rows_to_key_values(rows);
                Ok::<Vec<KeyValue>, ServerError>(kvs)
            })
        })
        .await
    }

    async fn batch_delete(&self, keys: Vec<String>) -> Result<(), ServerError> {
        self.transaction(|transaction| {
            Box::pin(async move {
                let sql = RawSqlBuilder::delete_from(KV_TABLE).and_where_in("id", &keys).sql()?;
                let _ = sqlx::query(&sql).execute(transaction).await.map_err(map_sqlx_error)?;

                Ok::<(), ServerError>(())
            })
        })
        .await
    }

    async fn batch_get_start_with(&self, key: &str) -> Result<Vec<KeyValue>, ServerError> {
        let prefix = key.to_owned();
        self.transaction(|transaction| {
            Box::pin(async move {
                let sql = RawSqlBuilder::select_from(KV_TABLE)
                    .field("id")
                    .field("blob")
                    .and_where_like_left("id", &prefix)
                    .sql()?;

                let rows = sqlx::query(&sql).fetch_all(transaction).await.map_err(map_sqlx_error)?;

                let kvs = rows_to_key_values(rows);

                Ok::<Vec<KeyValue>, ServerError>(kvs)
            })
        })
        .await
    }

    async fn batch_delete_key_start_with(&self, keyword: &str) -> Result<(), ServerError> {
        let keyword = keyword.to_owned();
        self.transaction(|transaction| {
            Box::pin(async move {
                let sql = RawSqlBuilder::delete_from(KV_TABLE)
                    .and_where_like_left("id", &keyword)
                    .sql()?;

                let _ = sqlx::query(&sql).execute(transaction).await.map_err(map_sqlx_error)?;
                Ok::<(), ServerError>(())
            })
        })
        .await
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
