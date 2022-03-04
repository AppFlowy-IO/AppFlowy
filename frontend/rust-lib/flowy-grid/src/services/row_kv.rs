use async_trait::async_trait;
use diesel::SqliteConnection;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::RawRow;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_sqlite::{ConnectionManager, ConnectionPool};
use std::sync::Arc;

pub trait RowKVTransaction {
    fn get(&self, row_id: &str) -> FlowyResult<Option<RawRow>>;
    fn set(&self, row: RawRow) -> FlowyResult<()>;
    fn remove(&self, row_id: &str) -> FlowyResult<()>;

    fn batch_get(&self, ids: Vec<String>) -> FlowyResult<()>;
    fn batch_set(&self, rows: Vec<RawRow>) -> FlowyResult<()>;
    fn batch_delete(&self, ids: Vec<String>) -> FlowyResult<()>;
}

pub struct RowKVPersistence {
    pool: Arc<ConnectionPool>,
}

impl RowKVPersistence {
    pub fn new(pool: Arc<ConnectionPool>) -> Self {
        Self { pool }
    }

    pub fn begin_transaction<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: for<'a> FnOnce(Box<dyn RowKVTransaction + 'a>) -> FlowyResult<O>,
    {
        let conn = self.pool.get()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let sql_transaction = SqliteTransaction { conn: &conn };
            f(Box::new(sql_transaction))
        })
    }
}

impl RowKVTransaction for RowKVPersistence {
    fn get(&self, row_id: &str) -> FlowyResult<Option<RawRow>> {
        self.begin_transaction(|transaction| transaction.get(row_id))
    }

    fn set(&self, row: RawRow) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.set(row))
    }

    fn remove(&self, row_id: &str) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.remove(row_id))
    }

    fn batch_get(&self, ids: Vec<String>) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.batch_get(ids))
    }

    fn batch_set(&self, rows: Vec<RawRow>) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.batch_set(rows))
    }

    fn batch_delete(&self, ids: Vec<String>) -> FlowyResult<()> {
        self.begin_transaction(|transaction| transaction.batch_delete(ids))
    }
}

pub struct SqliteTransaction<'a> {
    conn: &'a SqliteConnection,
}

#[async_trait]
impl<'a> RowKVTransaction for SqliteTransaction<'a> {
    fn get(&self, row_id: &str) -> FlowyResult<Option<RawRow>> {
        todo!()
    }

    fn set(&self, row: RawRow) -> FlowyResult<()> {
        todo!()
    }

    fn remove(&self, row_id: &str) -> FlowyResult<()> {
        todo!()
    }

    fn batch_get(&self, ids: Vec<String>) -> FlowyResult<()> {
        todo!()
    }

    fn batch_set(&self, rows: Vec<RawRow>) -> FlowyResult<()> {
        todo!()
    }

    fn batch_delete(&self, ids: Vec<String>) -> FlowyResult<()> {
        todo!()
    }
}
