use crate::RevisionRecord;
use dashmap::DashMap;
use flowy_collaboration::entities::revision::RevisionRange;
use flowy_error::{FlowyError, FlowyResult};
use std::{borrow::Cow, sync::Arc, time::Duration};
use tokio::{sync::RwLock, task::JoinHandle};

pub(crate) trait RevisionMemoryCacheDelegate: Send + Sync {
    fn checkpoint_tick(&self, records: Vec<RevisionRecord>) -> FlowyResult<()>;
    fn receive_ack(&self, object_id: &str, rev_id: i64);
}

pub(crate) struct RevisionMemoryCache {
    object_id: String,
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    delegate: Arc<dyn RevisionMemoryCacheDelegate>,
    pending_write_revs: Arc<RwLock<Vec<i64>>>,
    defer_save: RwLock<Option<JoinHandle<()>>>,
}

impl RevisionMemoryCache {
    pub(crate) fn new(object_id: &str, delegate: Arc<dyn RevisionMemoryCacheDelegate>) -> Self {
        RevisionMemoryCache {
            object_id: object_id.to_owned(),
            revs_map: Arc::new(DashMap::new()),
            delegate,
            pending_write_revs: Arc::new(RwLock::new(vec![])),
            defer_save: RwLock::new(None),
        }
    }

    pub(crate) fn contains(&self, rev_id: &i64) -> bool { self.revs_map.contains_key(rev_id) }

    pub(crate) async fn add<'a>(&'a self, record: Cow<'a, RevisionRecord>) {
        let record = match record {
            Cow::Borrowed(record) => record.clone(),
            Cow::Owned(record) => record,
        };

        let rev_id = record.revision.rev_id;
        if self.revs_map.contains_key(&rev_id) {
            return;
        }

        if let Some(rev_id) = self.pending_write_revs.read().await.last() {
            if *rev_id >= record.revision.rev_id {
                tracing::error!("Duplicated revision added to memory_cache");
                return;
            }
        }
        self.revs_map.insert(rev_id, record);
        self.pending_write_revs.write().await.push(rev_id);
        self.make_checkpoint().await;
    }

    pub(crate) async fn ack(&self, rev_id: &i64) {
        match self.revs_map.get_mut(rev_id) {
            None => {},
            Some(mut record) => record.ack(),
        }

        if !self.pending_write_revs.read().await.contains(rev_id) {
            // The revision must be saved on disk if the pending_write_revs
            // doesn't contains the rev_id.
            self.delegate.receive_ack(&self.object_id, *rev_id);
        } else {
            self.make_checkpoint().await;
        }
    }

    pub(crate) async fn get(&self, rev_id: &i64) -> Option<RevisionRecord> {
        self.revs_map.get(&rev_id).map(|r| r.value().clone())
    }

    pub(crate) async fn get_with_range(&self, range: &RevisionRange) -> Result<Vec<RevisionRecord>, FlowyError> {
        let revs = range
            .iter()
            .flat_map(|rev_id| self.revs_map.get(&rev_id).map(|record| record.clone()))
            .collect::<Vec<RevisionRecord>>();
        Ok(revs)
    }

    pub(crate) async fn reset_with_revisions(&self, revision_records: &[RevisionRecord]) -> FlowyResult<()> {
        self.revs_map.clear();
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        let mut write_guard = self.pending_write_revs.write().await;
        write_guard.clear();
        for record in revision_records {
            self.revs_map.insert(record.revision.rev_id, record.clone());
            write_guard.push(record.revision.rev_id);
        }
        drop(write_guard);

        self.make_checkpoint().await;
        Ok(())
    }

    async fn make_checkpoint(&self) {
        // https://github.com/async-graphql/async-graphql/blob/ed8449beec3d9c54b94da39bab33cec809903953/src/dataloader/mod.rs#L362
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        if self.pending_write_revs.read().await.is_empty() {
            return;
        }

        let rev_map = self.revs_map.clone();
        let pending_write_revs = self.pending_write_revs.clone();
        let delegate = self.delegate.clone();

        *self.defer_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(600)).await;
            let mut revs_write_guard = pending_write_revs.write().await;
            // It may cause performance issues because we hold the write lock of the
            // rev_order and the lock will be released after the checkpoint has been written
            // to the disk.
            //
            // Use saturating_sub and split_off ?
            // https://stackoverflow.com/questions/28952411/what-is-the-idiomatic-way-to-pop-the-last-n-elements-in-a-mutable-vec
            let mut save_records: Vec<RevisionRecord> = vec![];
            revs_write_guard.iter().for_each(|rev_id| match rev_map.get(rev_id) {
                None => {},
                Some(value) => {
                    save_records.push(value.value().clone());
                },
            });

            if delegate.checkpoint_tick(save_records).is_ok() {
                revs_write_guard.clear();
                drop(revs_write_guard);
            }
        }));
    }
}
