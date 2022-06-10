use crate::{RevisionSnapshotDiskCache, RevisionSnapshotInfo};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use std::sync::Arc;

pub struct SQLiteRevisionSnapshotPersistence {
    object_id: String,
    pool: Arc<ConnectionPool>,
}

impl SQLiteRevisionSnapshotPersistence {
    pub fn new(object_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            object_id: object_id.to_string(),
            pool,
        }
    }
}

impl RevisionSnapshotDiskCache for SQLiteRevisionSnapshotPersistence {
    fn write_snapshot(&self, object_id: &str, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        todo!()
    }

    fn read_snapshot(&self, object_id: &str, rev_id: i64) -> FlowyResult<RevisionSnapshotInfo> {
        todo!()
    }
}
