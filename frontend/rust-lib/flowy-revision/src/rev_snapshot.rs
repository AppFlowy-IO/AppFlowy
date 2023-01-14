#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_variables)]
use crate::{RevIdCounter, RevisionMergeable, RevisionObjectDeserializer, RevisionPersistence};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_http_model::revision::Revision;
use std::sync::atomic::AtomicI64;
use std::sync::atomic::Ordering::SeqCst;
use std::sync::Arc;

pub trait RevisionSnapshotDiskCache: Send + Sync {
    fn should_generate_snapshot_from_range(&self, start_rev_id: i64, current_rev_id: i64) -> bool {
        (current_rev_id - start_rev_id) >= AUTO_GEN_SNAPSHOT_PER_10_REVISION
    }

    fn write_snapshot(&self, rev_id: i64, data: Vec<u8>) -> FlowyResult<()>;

    fn read_snapshot(&self, rev_id: i64) -> FlowyResult<Option<RevisionSnapshot>>;

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>>;
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

    fn read_last_snapshot(&self) -> FlowyResult<Option<RevisionSnapshot>> {
        Ok(None)
    }
}

const AUTO_GEN_SNAPSHOT_PER_10_REVISION: i64 = 10;

pub struct RevisionSnapshotController<Connection> {
    user_id: String,
    object_id: String,
    rev_snapshot_persistence: Arc<dyn RevisionSnapshotDiskCache>,
    rev_id_counter: Arc<RevIdCounter>,
    rev_persistence: Arc<RevisionPersistence<Connection>>,
    rev_compress: Arc<dyn RevisionMergeable>,
    start_rev_id: AtomicI64,
}

impl<Connection> RevisionSnapshotController<Connection>
where
    Connection: 'static,
{
    pub fn new<D>(
        user_id: &str,
        object_id: &str,
        disk_cache: D,
        rev_id_counter: Arc<RevIdCounter>,
        revision_persistence: Arc<RevisionPersistence<Connection>>,
        revision_compress: Arc<dyn RevisionMergeable>,
    ) -> Self
    where
        D: RevisionSnapshotDiskCache + 'static,
    {
        let disk_cache = Arc::new(disk_cache);
        Self {
            user_id: user_id.to_string(),
            object_id: object_id.to_string(),
            rev_snapshot_persistence: disk_cache,
            rev_id_counter,
            start_rev_id: AtomicI64::new(0),
            rev_persistence: revision_persistence,
            rev_compress: revision_compress,
        }
    }

    pub async fn generate_snapshot(&self) {
        if let Some((rev_id, bytes)) = self.generate_snapshot_data() {
            if let Err(e) = self.rev_snapshot_persistence.write_snapshot(rev_id, bytes.to_vec()) {
                tracing::error!("Save snapshot failed: {}", e);
            }
        }
    }

    /// Find the nearest revision base on the passed-in rev_id
    #[tracing::instrument(level = "trace", skip_all)]
    pub fn restore_from_snapshot<B>(&self, rev_id: i64) -> Option<(B::Output, Revision)>
    where
        B: RevisionObjectDeserializer,
    {
        tracing::info!("Try to find if {} has snapshot", self.object_id);
        let snapshot = self.rev_snapshot_persistence.read_last_snapshot().ok()??;
        let snapshot_rev_id = snapshot.rev_id;
        let revision = Revision::new(
            &self.object_id,
            snapshot.base_rev_id,
            snapshot.rev_id,
            snapshot.data,
            "".to_owned(),
        );
        tracing::info!(
            "Try to restore from snapshot: {}, {}",
            snapshot.base_rev_id,
            snapshot.rev_id
        );
        let object = B::deserialize_revisions(&self.object_id, vec![revision.clone()]).ok()?;
        tracing::info!(
            "Restore {} from snapshot with rev_id: {}",
            self.object_id,
            snapshot_rev_id
        );

        Some((object, revision))
    }

    pub fn generate_snapshot_if_need(&self) {
        let current_rev_id = self.rev_id_counter.value();
        let start_rev_id = self.get_start_rev_id();
        if current_rev_id <= start_rev_id {
            return;
        }
        if self
            .rev_snapshot_persistence
            .should_generate_snapshot_from_range(start_rev_id, current_rev_id)
        {
            if let Some((rev_id, bytes)) = self.generate_snapshot_data() {
                let disk_cache = self.rev_snapshot_persistence.clone();
                tokio::spawn(async move {
                    let _ = disk_cache.write_snapshot(rev_id, bytes.to_vec());
                });
            }
            self.set_start_rev_id(current_rev_id);
        }
    }

    fn generate_snapshot_data(&self) -> Option<(i64, Bytes)> {
        let revisions = self
            .rev_persistence
            .load_all_records(&self.object_id)
            .map(|records| {
                records
                    .into_iter()
                    .map(|record| record.revision)
                    .collect::<Vec<Revision>>()
            })
            .ok()?;

        if revisions.is_empty() {
            return None;
        }

        let data = self.rev_compress.combine_revisions(revisions).ok()?;
        let rev_id = self.rev_id_counter.value();
        Some((rev_id, data))
    }

    fn get_start_rev_id(&self) -> i64 {
        self.start_rev_id.load(SeqCst)
    }

    fn set_start_rev_id(&self, rev_id: i64) {
        let _ = self.start_rev_id.fetch_update(SeqCst, SeqCst, |_| Some(rev_id));
    }
}

impl<Connection> std::ops::Deref for RevisionSnapshotController<Connection> {
    type Target = Arc<dyn RevisionSnapshotDiskCache>;

    fn deref(&self) -> &Self::Target {
        &self.rev_snapshot_persistence
    }
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct RevisionSnapshot {
    pub rev_id: i64,
    pub base_rev_id: i64,
    pub timestamp: i64,
    pub data: Bytes,
}
