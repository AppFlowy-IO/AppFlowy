use bytes::Bytes;
use flowy_database::{
    prelude::*,
    schema::{grid_rev_snapshot, grid_rev_snapshot::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyResult};
use flowy_revision::{RevisionSnapshot, RevisionSnapshotDiskCache};
use lib_infra::util::timestamp;
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

    fn gen_snapshot_id(&self, rev_id: i64) -> String {
        format!("{}:{}", self.object_id, rev_id)
    }
}

impl RevisionSnapshotDiskCache for SQLiteGridRevisionSnapshotPersistence {
    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        let conn = self.pool.get().map_err(internal_error)?;
        let snapshot_id = self.gen_snapshot_id(rev_id);
        let timestamp = timestamp();
        let record = (
            dsl::snapshot_id.eq(&snapshot_id),
            dsl::object_id.eq(&self.object_id),
            dsl::rev_id.eq(rev_id),
            dsl::base_rev_id.eq(rev_id),
            dsl::timestamp.eq(timestamp),
            dsl::data.eq(data),
        );
        let _ = insert_or_ignore_into(dsl::grid_rev_snapshot)
            .values(record)
            .execute(&*conn)?;
        Ok(())

        // conn.immediate_transaction::<_, FlowyError, _>(|| {
        //     let filter = dsl::grid_rev_snapshot
        //         .filter(dsl::object_id.eq(&self.object_id))
        //         .filter(dsl::rev_id.eq(rev_id));
        //
        //     let is_exist: bool = select(exists(filter)).get_result(&*conn)?;
        //     match is_exist {
        //         false => {
        //             let record = (
        //                 dsl::object_id.eq(&self.object_id),
        //                 dsl::rev_id.eq(rev_id),
        //                 dsl::data.eq(data),
        //             );
        //             insert_or_ignore_into(dsl::grid_rev_snapshot)
        //                 .values(record)
        //                 .execute(&*conn)?;
        //         }
        //         true => {
        //             let affected_row = update(filter).set(dsl::data.eq(data)).execute(&*conn)?;
        //             debug_assert_eq!(affected_row, 1);
        //         }
        //     }
        //     Ok(())
        // })
    }

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let snapshot_id = self.gen_snapshot_id(rev_id);
        let record = dsl::grid_rev_snapshot
            .filter(dsl::snapshot_id.eq(&snapshot_id))
            .first::<GridSnapshotRecord>(&*conn)?;

        Ok(Some(record.into()))
    }

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let latest_record = dsl::grid_rev_snapshot
            .filter(dsl::object_id.eq(&self.object_id))
            .order(dsl::rev_id.desc())
            // .select(max(dsl::rev_id))
            // .select((dsl::id, dsl::object_id, dsl::rev_id, dsl::data))
            .first::<GridSnapshotRecord>(&*conn)?;
        Ok(Some(latest_record.into()))
    }
}
#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "grid_rev_snapshot"]
#[primary_key("snapshot_id")]
struct GridSnapshotRecord {
    snapshot_id: String,
    object_id: String,
    rev_id: i64,
    base_rev_id: i64,
    timestamp: i64,
    data: Vec<u8>,
}

impl std::convert::From<GridSnapshotRecord> for RevisionSnapshot {
    fn from(record: GridSnapshotRecord) -> Self {
        RevisionSnapshot {
            rev_id: record.rev_id,
            base_rev_id: record.base_rev_id,
            timestamp: record.timestamp,
            data: Bytes::from(record.data),
        }
    }
}

// pub(crate) fn get_latest_rev_id_from(rev_ids: Vec<i64>, anchor: i64) -> Option<i64> {
//     let mut target_rev_id = None;
//     let mut old_step: Option<i64> = None;
//     for rev_id in rev_ids {
//         let step = (rev_id - anchor).abs();
//         if let Some(old_step) = &mut old_step {
//             if *old_step > step {
//                 *old_step = step;
//                 target_rev_id = Some(rev_id);
//             }
//         } else {
//             old_step = Some(step);
//             target_rev_id = Some(rev_id);
//         }
//     }
//     target_rev_id
// }

// #[cfg(test)]
// mod tests {
//     use crate::services::persistence::rev_sqlite::get_latest_rev_id_from;
//
//     #[test]
//     fn test_latest_rev_id() {
//         let ids = vec![1, 2, 3, 4, 5, 6];
//         for (anchor, expected_value) in vec![(3, 3), (7, 6), (1, 1)] {
//             let value = get_latest_rev_id_from(ids.clone(), anchor).unwrap();
//             assert_eq!(value, expected_value);
//         }
//     }
// }
