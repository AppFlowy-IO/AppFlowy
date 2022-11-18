#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_variables)]
use crate::{RevisionSnapshotDiskCache, RevisionSnapshotInfo};
use flowy_error::FlowyResult;

pub struct SQLiteRevisionSnapshotPersistence<Connection> {
    object_id: String,
    pool: Connection,
}

impl<Connection: 'static> SQLiteRevisionSnapshotPersistence<Connection> {
    pub fn new(object_id: &str, pool: Connection) -> Self {
        Self {
            object_id: object_id.to_string(),
            pool,
        }
    }
}

impl<Connection> RevisionSnapshotDiskCache for SQLiteRevisionSnapshotPersistence<Connection>
where
    Connection: Send + Sync + 'static,
{
    fn write_snapshot(&self, object_id: &str, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        todo!()
    }

    fn read_snapshot(&self, object_id: &str, rev_id: i64) -> FlowyResult<RevisionSnapshotInfo> {
        todo!()
    }
}
