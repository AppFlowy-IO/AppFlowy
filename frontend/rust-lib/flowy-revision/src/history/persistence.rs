use crate::history::RevisionHistoryDiskCache;
use diesel::{sql_types::Integer, update, SqliteConnection};
use flowy_database::{
    prelude::*,
    schema::{rev_history, rev_history::dsl},
    ConnectionPool,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::revision::Revision;
use std::sync::Arc;

pub struct SQLiteRevisionHistoryPersistence {
    pool: Arc<ConnectionPool>,
}

impl SQLiteRevisionHistoryPersistence {
    pub fn new(pool: Arc<ConnectionPool>) -> Self {
        Self { pool }
    }
}

impl RevisionHistoryDiskCache for SQLiteRevisionHistoryPersistence {
    fn save_revision(&self, revision: Revision) -> FlowyResult<()> {
        todo!()
    }

    fn read_revision(&self, rev_id: i64) -> FlowyResult<Revision> {
        todo!()
    }

    fn clear(&self) -> FlowyResult<()> {
        todo!()
    }
}

struct RevisionHistorySql();
impl RevisionHistorySql {
    fn read_revision(object_id: &str, rev_id: i64, conn: &SqliteConnection) -> Result<Revision, FlowyError> {
        let records: Vec<RevisionRecord> = dsl::rev_history
            .filter(dsl::start_rev_id.lt(rev_id))
            .filter(dsl::end_rev_id.ge(rev_id))
            .filter(dsl::object_id.eq(object_id))
            .load::<RevisionRecord>(conn)?;

        debug_assert_eq!(records.len(), 1);

        todo!()
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_history"]
struct RevisionRecord {
    id: i32,
    object_id: String,
    start_rev_id: i64,
    end_rev_id: i64,
    data: Vec<u8>,
}
