use crate::{
    services::kv::{KVStore, KeyValue},
    util::sqlx_ext::{map_sqlx_error, SqlBuilder},
};

use anyhow::Context;
use backend_service::errors::ServerError;
use bytes::Bytes;
use lib_infra::future::FutureResultSend;
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

pub(crate) struct PostgresKV {
    pub(crate) pg_pool: PgPool,
}

impl KVStore for PostgresKV {
    fn get(&self, key: &str) -> FutureResultSend<Option<Bytes>, ServerError> {
        let pg_pool = self.pg_pool.clone();
        let id = key.to_string();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let (sql, args) = SqlBuilder::select(KV_TABLE)
                .add_field("*")
                .and_where_eq("id", &id)
                .build()?;

            let result = sqlx::query_as_with::<Postgres, KVTable, PgArguments>(&sql, args)
                .fetch_one(&mut transaction)
                .await;

            let result = match result {
                Ok(val) => Ok(Some(Bytes::from(val.blob))),
                Err(error) => match error {
                    Error::RowNotFound => Ok(None),
                    _ => Err(map_sqlx_error(error)),
                },
            };

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            result
        })
    }

    fn set(&self, key: &str, bytes: Bytes) -> FutureResultSend<(), ServerError> {
        self.batch_set(vec![KeyValue {
            key: key.to_string(),
            value: bytes,
        }])
    }

    fn delete(&self, key: &str) -> FutureResultSend<(), ServerError> {
        let pg_pool = self.pg_pool.clone();
        let id = key.to_string();

        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let (sql, args) = SqlBuilder::delete(KV_TABLE).and_where_eq("id", &id).build()?;
            let _ = sqlx::query_with(&sql, args)
                .execute(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok(())
        })
    }

    fn batch_set(&self, kvs: Vec<KeyValue>) -> FutureResultSend<(), ServerError> {
        let pg_pool = self.pg_pool.clone();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            SqlBuilder::create(KV_TABLE).add_field("id").add_field("blob");
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
                .execute(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok::<(), ServerError>(())
        })
    }

    fn batch_get(&self, keys: Vec<String>) -> FutureResultSend<Vec<KeyValue>, ServerError> {
        let pg_pool = self.pg_pool.clone();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let sql = RawSqlBuilder::select_from(KV_TABLE)
                .field("id")
                .field("blob")
                .and_where_in_quoted("id", &keys)
                .sql()?;

            let rows = sqlx::query(&sql)
                .fetch_all(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;
            let kvs = rows_to_key_values(rows);

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok::<Vec<KeyValue>, ServerError>(kvs)
        })
    }

    fn batch_get_start_with(&self, key: &str) -> FutureResultSend<Vec<KeyValue>, ServerError> {
        let pg_pool = self.pg_pool.clone();
        let prefix = key.to_owned();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let sql = RawSqlBuilder::select_from(KV_TABLE)
                .field("id")
                .field("blob")
                .and_where_like_left("id", &prefix)
                .sql()?;

            let rows = sqlx::query(&sql)
                .fetch_all(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;

            let kvs = rows_to_key_values(rows);

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok::<Vec<KeyValue>, ServerError>(kvs)
        })
    }

    fn batch_delete(&self, keys: Vec<String>) -> FutureResultSend<(), ServerError> {
        let pg_pool = self.pg_pool.clone();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let sql = RawSqlBuilder::delete_from(KV_TABLE).and_where_in("id", &keys).sql()?;

            let _ = sqlx::query(&sql)
                .execute(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok::<(), ServerError>(())
        })
    }

    fn batch_delete_key_start_with(&self, keyword: &str) -> FutureResultSend<(), ServerError> {
        let pg_pool = self.pg_pool.clone();
        let keyword = keyword.to_owned();
        FutureResultSend::new(async move {
            let mut transaction = pg_pool
                .begin()
                .await
                .context("[KV]:Failed to acquire a Postgres connection")?;

            let sql = RawSqlBuilder::delete_from(KV_TABLE)
                .and_where_like_left("id", &keyword)
                .sql()?;

            let _ = sqlx::query(&sql)
                .execute(&mut transaction)
                .await
                .map_err(map_sqlx_error)?;

            transaction
                .commit()
                .await
                .context("[KV]:Failed to commit SQL transaction.")?;

            Ok::<(), ServerError>(())
        })
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
