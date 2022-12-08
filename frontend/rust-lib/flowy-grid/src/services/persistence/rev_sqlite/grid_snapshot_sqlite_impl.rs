// use diesel::dsl::exists;
use bytes::Bytes;
use diesel::dsl::exists;
use flowy_database::{
    prelude::*,
    schema::{rev_snapshot, rev_snapshot::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_revision::{RevisionSnapshot, RevisionSnapshotDiskCache};
use std::sync::Arc;

pub struct SQLiteGridRevisionSnapshotPersistence {
    object_id: String,
    pool: Arc<ConnectionPool>,
}

impl SQLiteGridRevisionSnapshotPersistence {
    pub fn new(object_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            object_id: object_id.to_string(),
            pool,
        }
    }
}

impl RevisionSnapshotDiskCache for SQLiteGridRevisionSnapshotPersistence {
    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        let conn = self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let filter = dsl::rev_snapshot
                .filter(dsl::object_id.eq(&self.object_id))
                .filter(dsl::rev_id.eq(rev_id));

            let is_exist: bool = select(exists(filter)).get_result(&*conn)?;
            match is_exist {
                false => {
                    let record = (
                        dsl::object_id.eq(&self.object_id),
                        dsl::rev_id.eq(rev_id),
                        dsl::data.eq(data),
                    );
                    insert_or_ignore_into(dsl::rev_snapshot)
                        .values(record)
                        .execute(&*conn)?;
                }
                true => {
                    let affected_row = update(filter).set(dsl::data.eq(data)).execute(&*conn)?;
                    debug_assert_eq!(affected_row, 1);
                }
            }
            Ok(())
        })
    }

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let record = dsl::rev_snapshot
            .filter(dsl::object_id.eq(&self.object_id))
            .filter(dsl::rev_id.eq(rev_id))
            .first::<GridSnapshotRecord>(&*conn)?;

        Ok(Some(record.into()))
    }

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let latest_record = dsl::rev_snapshot
            .order(dsl::rev_id.desc())
            // .select(max(dsl::rev_id))
            // .select((dsl::id, dsl::object_id, dsl::rev_id, dsl::data))
            .first::<GridSnapshotRecord>(&*conn)?;
        Ok(Some(latest_record.into()))
    }

    fn latest_snapshot_from(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let records = dsl::rev_snapshot
            .filter(dsl::object_id.eq(&self.object_id))
            .filter(dsl::rev_id.ge(rev_id))
            .filter(dsl::rev_id.le(rev_id))
            .load::<GridSnapshotRecord>(&*conn)?;

        let mut record: Option<RevisionSnapshot> = None;
        let mut min_offset: Option<i64> = None;
        for element in records.into_iter() {
            let offset = element.rev_id - rev_id;
            if let Some(min_offset) = &mut min_offset {
                if *min_offset > offset {
                    *min_offset = offset;
                    record = Some(element.into());
                }
            } else {
                min_offset = Some(offset);
                record = Some(element.into());
            }
        }
        Ok(record)
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_snapshot"]
struct GridSnapshotRecord {
    id: i32,
    object_id: String,
    rev_id: i64,
    data: Vec<u8>,
}

impl std::convert::From<GridSnapshotRecord> for RevisionSnapshot {
    fn from(record: GridSnapshotRecord) -> Self {
        let base_rev_id = if record.rev_id > 0 { record.rev_id - 1 } else { 0 };
        let rev_id = record.rev_id;
        RevisionSnapshot {
            rev_id,
            base_rev_id,
            data: Bytes::from(record.data),
        }
    }
}
