use crate::disk::SyncRecord;
use crate::REVISION_WRITE_INTERVAL_IN_MILLIS;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::revision::RevisionRange;
use std::{borrow::Cow, sync::Arc, time::Duration};
use tokio::{sync::RwLock, task::JoinHandle};

pub(crate) trait RevisionMemoryCacheDelegate: Send + Sync {
    fn send_sync(&self, records: Vec<SyncRecord>) -> FlowyResult<()>;
    fn receive_ack(&self, object_id: &str, rev_id: i64);
}

pub(crate) struct RevisionMemoryCache {
    object_id: String,
    revs_map: Arc<DashMap<i64, SyncRecord>>,
    delegate: Arc<dyn RevisionMemoryCacheDelegate>,
    defer_write_revs: Arc<RwLock<Vec<i64>>>,
    defer_save: RwLock<Option<JoinHandle<()>>>,
}

impl RevisionMemoryCache {
    pub(crate) fn new(object_id: &str, delegate: Arc<dyn RevisionMemoryCacheDelegate>) -> Self {
        RevisionMemoryCache {
            object_id: object_id.to_owned(),
            revs_map: Arc::new(DashMap::new()),
            delegate,
            defer_write_revs: Arc::new(RwLock::new(vec![])),
            defer_save: RwLock::new(None),
        }
    }

    pub(crate) fn contains(&self, rev_id: &i64) -> bool {
        self.revs_map.contains_key(rev_id)
    }

    pub(crate) async fn add<'a>(&'a self, record: Cow<'a, SyncRecord>) {
        let record = match record {
            Cow::Borrowed(record) => record.clone(),
            Cow::Owned(record) => record,
        };

        let rev_id = record.revision.rev_id;
        self.revs_map.insert(rev_id, record);

        let mut write_guard = self.defer_write_revs.write().await;
        if !write_guard.contains(&rev_id) {
            write_guard.push(rev_id);
            drop(write_guard);
            self.tick_checkpoint().await;
        }
    }

    pub(crate) async fn ack(&self, rev_id: &i64) {
        match self.revs_map.get_mut(rev_id) {
            None => {}
            Some(mut record) => record.ack(),
        }

        if self.defer_write_revs.read().await.contains(rev_id) {
            self.tick_checkpoint().await;
        } else {
            // The revision must be saved on disk if the pending_write_revs
            // doesn't contains the rev_id.
            self.delegate.receive_ack(&self.object_id, *rev_id);
        }
    }

    pub(crate) async fn get(&self, rev_id: &i64) -> Option<SyncRecord> {
        self.revs_map.get(rev_id).map(|r| r.value().clone())
    }

    pub(crate) fn remove(&self, rev_id: &i64) {
        let _ = self.revs_map.remove(rev_id);
    }

    pub(crate) fn remove_with_range(&self, range: &RevisionRange) {
        for rev_id in range.iter() {
            self.remove(&rev_id);
        }
    }

    pub(crate) async fn get_with_range(&self, range: &RevisionRange) -> Result<Vec<SyncRecord>, FlowyError> {
        let revs = range
            .iter()
            .flat_map(|rev_id| self.revs_map.get(&rev_id).map(|record| record.clone()))
            .collect::<Vec<SyncRecord>>();
        Ok(revs)
    }

    pub(crate) async fn reset_with_revisions(&self, revision_records: Vec<SyncRecord>) {
        self.revs_map.clear();
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        let mut write_guard = self.defer_write_revs.write().await;
        write_guard.clear();
        for record in revision_records {
            write_guard.push(record.revision.rev_id);
            self.revs_map.insert(record.revision.rev_id, record);
        }
        drop(write_guard);

        self.tick_checkpoint().await;
    }

    async fn tick_checkpoint(&self) {
        // https://github.com/async-graphql/async-graphql/blob/ed8449beec3d9c54b94da39bab33cec809903953/src/dataloader/mod.rs#L362
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        if self.defer_write_revs.read().await.is_empty() {
            return;
        }

        let rev_map = self.revs_map.clone();
        let pending_write_revs = self.defer_write_revs.clone();
        let delegate = self.delegate.clone();

        *self.defer_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
            let mut revs_write_guard = pending_write_revs.write().await;
            // It may cause performance issues because we hold the write lock of the
            // rev_order and the lock will be released after the checkpoint has been written
            // to the disk.
            //
            // Use saturating_sub and split_off ?
            // https://stackoverflow.com/questions/28952411/what-is-the-idiomatic-way-to-pop-the-last-n-elements-in-a-mutable-vec
            let mut save_records: Vec<SyncRecord> = vec![];
            revs_write_guard.iter().for_each(|rev_id| match rev_map.get(rev_id) {
                None => {}
                Some(value) => {
                    save_records.push(value.value().clone());
                }
            });

            if delegate.send_sync(save_records).is_ok() {
                revs_write_guard.clear();
                drop(revs_write_guard);
            }
        }));
    }
}
