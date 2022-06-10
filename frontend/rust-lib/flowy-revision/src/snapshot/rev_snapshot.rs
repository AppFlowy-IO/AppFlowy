use flowy_error::FlowyResult;
use std::sync::Arc;

pub trait RevisionSnapshotDiskCache: Send + Sync {
    fn write_snapshot(&self, object_id: &str, rev_id: i64, data: Vec<u8>) -> FlowyResult<()>;
    fn read_snapshot(&self, object_id: &str, rev_id: i64) -> FlowyResult<RevisionSnapshotInfo>;
}

pub struct RevisionSnapshotManager {
    user_id: String,
    object_id: String,
    disk_cache: Arc<dyn RevisionSnapshotDiskCache>,
}

impl RevisionSnapshotManager {
    pub fn new<D>(user_id: &str, object_id: &str, disk_cache: D) -> Self
    where
        D: RevisionSnapshotDiskCache + 'static,
    {
        let disk_cache = Arc::new(disk_cache);
        Self {
            user_id: user_id.to_string(),
            object_id: object_id.to_string(),
            disk_cache,
        }
    }
}

pub struct RevisionSnapshotInfo {}
