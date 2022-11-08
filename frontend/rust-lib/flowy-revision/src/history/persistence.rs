use crate::history::RevisionHistoryDiskCache;
use flowy_database::{
    prelude::*,
    schema::{rev_history, rev_history::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyResult};
use flowy_http_model::revision::Revision;
use std::sync::Arc;

pub struct SQLiteRevisionHistoryPersistence {
    object_id: String,
    pool: Arc<ConnectionPool>,
}

impl SQLiteRevisionHistoryPersistence {
    pub fn new(object_id: &str, pool: Arc<ConnectionPool>) -> Self {
        let object_id = object_id.to_owned();
        Self { object_id, pool }
    }
}

impl RevisionHistoryDiskCache for SQLiteRevisionHistoryPersistence {
    fn write_history(&self, revision: Revision) -> FlowyResult<()> {
        let record = (
            dsl::object_id.eq(revision.object_id),
            dsl::start_rev_id.eq(revision.base_rev_id),
            dsl::end_rev_id.eq(revision.rev_id),
            dsl::data.eq(revision.delta_data),
        );
        let conn = self.pool.get().map_err(internal_error)?;

        let _ = insert_or_ignore_into(dsl::rev_history)
            .values(vec![record])
            .execute(&*conn)?;
        Ok(())
    }

    fn read_histories(&self) -> FlowyResult<Vec<RevisionHistory>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let records: Vec<RevisionRecord> = dsl::rev_history
            .filter(dsl::object_id.eq(&self.object_id))
            .load::<RevisionRecord>(&*conn)?;

        Ok(records
            .into_iter()
            .map(|record| record.into())
            .collect::<Vec<RevisionHistory>>())
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

pub struct RevisionHistory {
    pub object_id: String,
    pub start_rev_id: i64,
    pub end_rev_id: i64,
    pub data: Vec<u8>,
}

impl std::convert::From<RevisionRecord> for RevisionHistory {
    fn from(record: RevisionRecord) -> Self {
        RevisionHistory {
            object_id: record.object_id,
            start_rev_id: record.start_rev_id,
            end_rev_id: record.end_rev_id,
            data: record.data,
        }
    }
}
