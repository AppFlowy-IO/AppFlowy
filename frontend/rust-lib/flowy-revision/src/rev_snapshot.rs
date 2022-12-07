#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_variables)]
use flowy_error::FlowyResult;
use std::sync::Arc;

pub trait RevisionSnapshotDiskCache: Send + Sync {
    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()>;
    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>>;
    fn read_latest_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>>;
}

/// Do nothing but just used to clam the rust compiler about the generic parameter `SP` of `RevisionManager`
///  
pub struct PhantomSnapshotPersistence();
impl RevisionSnapshotDiskCache for PhantomSnapshotPersistence {
    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()> {
        Ok(())
    }

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>> {
        Ok(None)
    }

    fn read_latest_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        Ok(None)
    }
}

pub struct RevisionSnapshotController {
    user_id: String,
    object_id: String,
    disk_cache: Arc<dyn RevisionSnapshotDiskCache>,
}

impl RevisionSnapshotController {
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

impl std::ops::Deref for RevisionSnapshotController {
    type Target = Arc<dyn RevisionSnapshotDiskCache>;

    fn deref(&self) -> &Self::Target {
        &self.disk_cache
    }
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct RevisionSnapshot {
    pub rev_id: i64,
    pub data: Vec<u8>,
}
