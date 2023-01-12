#![allow(clippy::unused_unit)]
use bytes::Bytes;
use flowy_database::{
    prelude::*,
    schema::{folder_rev_snapshot, folder_rev_snapshot::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyResult};
use flowy_revision::{RevisionSnapshot, RevisionSnapshotDiskCache};
use lib_infra::util::timestamp;
use std::sync::Arc;

pub struct SQLiteFolderRevisionSnapshotPersistence {
    object_id: String,
    pool: Arc<ConnectionPool>,
}

impl SQLiteFolderRevisionSnapshotPersistence {
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

impl RevisionSnapshotDiskCache for SQLiteFolderRevisionSnapshotPersistence {
    fn should_generate_snapshot_from_range(&self, start_rev_id: i64, current_rev_id: i64) -> bool {
        (current_rev_id - start_rev_id) >= 2
    }

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
        let _ = insert_or_ignore_into(dsl::folder_rev_snapshot)
            .values(record)
            .execute(&*conn)?;
        Ok(())
    }

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let snapshot_id = self.gen_snapshot_id(rev_id);
        let record = dsl::folder_rev_snapshot
            .filter(dsl::snapshot_id.eq(&snapshot_id))
            .first::<FolderSnapshotRecord>(&*conn)?;

        Ok(Some(record.into()))
    }

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let latest_record = dsl::folder_rev_snapshot
            .filter(dsl::object_id.eq(&self.object_id))
            .order(dsl::rev_id.desc())
            // .select(max(dsl::rev_id))
            // .select((dsl::id, dsl::object_id, dsl::rev_id, dsl::data))
            .first::<FolderSnapshotRecord>(&*conn)?;
        Ok(Some(latest_record.into()))
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "folder_rev_snapshot"]
#[primary_key("snapshot_id")]
struct FolderSnapshotRecord {
    snapshot_id: String,
    object_id: String,
    rev_id: i64,
    base_rev_id: i64,
    timestamp: i64,
    data: Vec<u8>,
}

impl std::convert::From<FolderSnapshotRecord> for RevisionSnapshot {
    fn from(record: FolderSnapshotRecord) -> Self {
        RevisionSnapshot {
            rev_id: record.rev_id,
            base_rev_id: record.base_rev_id,
            timestamp: record.timestamp,
            data: Bytes::from(record.data),
        }
    }
}
