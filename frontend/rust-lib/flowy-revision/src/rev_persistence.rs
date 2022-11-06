use crate::cache::{
    disk::{RevisionChangeset, RevisionDiskCache},
    memory::RevisionMemoryCacheDelegate,
};
use crate::disk::{RevisionState, SyncRecord};
use crate::memory::RevisionMemoryCache;
use crate::RevisionMergeable;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_sync::entities::revision::{Revision, RevisionRange};
use std::collections::VecDeque;
use std::{borrow::Cow, sync::Arc};
use tokio::sync::RwLock;
use tokio::task::spawn_blocking;

pub const REVISION_WRITE_INTERVAL_IN_MILLIS: u64 = 600;

pub struct RevisionPersistenceConfiguration {
    merge_threshold: usize,
}

impl RevisionPersistenceConfiguration {
    pub fn new(merge_threshold: usize) -> Self {
        debug_assert!(merge_threshold > 1);
        if merge_threshold > 1 {
            Self { merge_threshold }
        } else {
            Self { merge_threshold: 2 }
        }
    }
}

impl std::default::Default for RevisionPersistenceConfiguration {
    fn default() -> Self {
        Self { merge_threshold: 2 }
    }
}

pub struct RevisionPersistence<Connection> {
    user_id: String,
    object_id: String,
    disk_cache: Arc<dyn RevisionDiskCache<Connection, Error = FlowyError>>,
    memory_cache: Arc<RevisionMemoryCache>,
    sync_seq: RwLock<DeferSyncSequence>,
    configuration: RevisionPersistenceConfiguration,
}

impl<Connection> RevisionPersistence<Connection>
where
    Connection: 'static,
{
    pub fn new<C>(
        user_id: &str,
        object_id: &str,
        disk_cache: C,
        configuration: RevisionPersistenceConfiguration,
    ) -> RevisionPersistence<Connection>
    where
        C: 'static + RevisionDiskCache<Connection, Error = FlowyError>,
    {
        let disk_cache = Arc::new(disk_cache) as Arc<dyn RevisionDiskCache<Connection, Error = FlowyError>>;
        Self::from_disk_cache(user_id, object_id, disk_cache, configuration)
    }

    pub fn from_disk_cache(
        user_id: &str,
        object_id: &str,
        disk_cache: Arc<dyn RevisionDiskCache<Connection, Error = FlowyError>>,
        configuration: RevisionPersistenceConfiguration,
    ) -> RevisionPersistence<Connection> {
        let object_id = object_id.to_owned();
        let user_id = user_id.to_owned();
        let sync_seq = RwLock::new(DeferSyncSequence::new());
        let memory_cache = Arc::new(RevisionMemoryCache::new(&object_id, Arc::new(disk_cache.clone())));
        Self {
            user_id,
            object_id,
            disk_cache,
            memory_cache,
            sync_seq,
            configuration,
        }
    }

    /// Save the revision that comes from remote to disk.
    #[tracing::instrument(level = "trace", skip(self, revision), fields(rev_id, object_id=%self.object_id), err)]
    pub(crate) async fn add_ack_revision(&self, revision: &Revision) -> FlowyResult<()> {
        tracing::Span::current().record("rev_id", &revision.rev_id);
        self.add(revision.clone(), RevisionState::Ack, true).await
    }

    /// Append the revision that already existed in the local DB state to sync sequence
    #[tracing::instrument(level = "trace", skip(self), fields(rev_id, object_id=%self.object_id), err)]
    pub(crate) async fn sync_revision(&self, revision: &Revision) -> FlowyResult<()> {
        tracing::Span::current().record("rev_id", &revision.rev_id);
        self.add(revision.clone(), RevisionState::Sync, false).await?;
        self.sync_seq.write().await.dry_push(revision.rev_id)?;
        Ok(())
    }

    /// Save the revision to disk and append it to the end of the sync sequence.
    #[tracing::instrument(level = "trace", skip_all, fields(rev_id, compact_range, object_id=%self.object_id), err)]
    pub(crate) async fn add_sync_revision<'a>(
        &'a self,
        new_revision: &'a Revision,
        rev_compress: &Arc<dyn RevisionMergeable + 'a>,
    ) -> FlowyResult<i64> {
        let mut sync_seq_write_guard = self.sync_seq.write().await;
        if sync_seq_write_guard.step > self.configuration.merge_threshold {
            let compact_seq = sync_seq_write_guard.compact();
            let range = RevisionRange {
                start: *compact_seq.front().unwrap(),
                end: *compact_seq.back().unwrap(),
            };

            tracing::Span::current().record("compact_range", &format!("{}", range).as_str());
            let mut revisions = self.revisions_in_range(&range).await?;
            debug_assert_eq!(range.len() as usize, revisions.len());
            // append the new revision
            revisions.push(new_revision.clone());

            // compact multiple revisions into one
            let compact_revision = rev_compress.merge_revisions(&self.user_id, &self.object_id, revisions)?;
            let rev_id = compact_revision.rev_id;
            tracing::Span::current().record("rev_id", &rev_id);

            // insert new revision
            let _ = sync_seq_write_guard.dry_push(rev_id)?;

            // replace the revisions in range with compact revision
            self.compact(&range, compact_revision).await?;
            Ok(rev_id)
        } else {
            tracing::Span::current().record("rev_id", &new_revision.rev_id);
            self.add(new_revision.clone(), RevisionState::Sync, true).await?;
            sync_seq_write_guard.push(new_revision.rev_id)?;
            Ok(new_revision.rev_id)
        }
    }

    /// Remove the revision with rev_id from the sync sequence.
    pub(crate) async fn ack_revision(&self, rev_id: i64) -> FlowyResult<()> {
        if self.sync_seq.write().await.ack(&rev_id).is_ok() {
            self.memory_cache.ack(&rev_id).await;
        }
        Ok(())
    }

    pub(crate) async fn next_sync_revision(&self) -> FlowyResult<Option<Revision>> {
        match self.sync_seq.read().await.next_rev_id() {
            None => Ok(None),
            Some(rev_id) => Ok(self.get(rev_id).await.map(|record| record.revision)),
        }
    }

    pub(crate) async fn next_sync_rev_id(&self) -> Option<i64> {
        self.sync_seq.read().await.next_rev_id()
    }

    pub(crate) fn number_of_sync_records(&self) -> usize {
        self.memory_cache.number_of_sync_records()
    }

    /// The cache gets reset while it conflicts with the remote revisions.
    #[tracing::instrument(level = "trace", skip(self, revisions), err)]
    pub(crate) async fn reset(&self, revisions: Vec<Revision>) -> FlowyResult<()> {
        let records = revisions
            .into_iter()
            .map(|revision| SyncRecord {
                revision,
                state: RevisionState::Sync,
                write_to_disk: false,
            })
            .collect::<Vec<_>>();

        let _ = self
            .disk_cache
            .delete_and_insert_records(&self.object_id, None, records.clone())?;
        let _ = self.memory_cache.reset_with_revisions(records).await;
        self.sync_seq.write().await.clear();
        Ok(())
    }

    async fn add(&self, revision: Revision, state: RevisionState, write_to_disk: bool) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            tracing::warn!("Duplicate revision: {}:{}-{:?}", self.object_id, revision.rev_id, state);
            return Ok(());
        }
        let record = SyncRecord {
            revision,
            state,
            write_to_disk,
        };

        self.memory_cache.add(Cow::Owned(record)).await;
        Ok(())
    }

    async fn compact(&self, range: &RevisionRange, new_revision: Revision) -> FlowyResult<()> {
        self.memory_cache.remove_with_range(range);
        let rev_ids = range.to_rev_ids();
        let _ = self
            .disk_cache
            .delete_revision_records(&self.object_id, Some(rev_ids))?;

        self.add(new_revision, RevisionState::Sync, true).await?;
        Ok(())
    }

    pub async fn get(&self, rev_id: i64) -> Option<SyncRecord> {
        match self.memory_cache.get(&rev_id).await {
            None => match self
                .disk_cache
                .read_revision_records(&self.object_id, Some(vec![rev_id]))
            {
                Ok(mut records) => {
                    let record = records.pop()?;
                    assert!(records.is_empty());
                    Some(record)
                }
                Err(e) => {
                    tracing::error!("{}", e);
                    None
                }
            },
            Some(revision) => Some(revision),
        }
    }

    pub fn batch_get(&self, doc_id: &str) -> FlowyResult<Vec<SyncRecord>> {
        self.disk_cache.read_revision_records(doc_id, None)
    }

    // Read the revision which rev_id >= range.start && rev_id <= range.end
    pub async fn revisions_in_range(&self, range: &RevisionRange) -> FlowyResult<Vec<Revision>> {
        let range = range.clone();
        let mut records = self.memory_cache.get_with_range(&range).await?;
        let range_len = range.len() as usize;
        if records.len() != range_len {
            let disk_cache = self.disk_cache.clone();
            let object_id = self.object_id.clone();
            records = spawn_blocking(move || disk_cache.read_revision_records_with_range(&object_id, &range))
                .await
                .map_err(internal_error)??;

            if records.len() != range_len {
                // #[cfg(debug_assertions)]
                // records.iter().for_each(|record| {
                //     let delta = PlainDelta::from_bytes(&record.revision.delta_data).unwrap();
                //     tracing::trace!("{}", delta.to_string());
                // });
                tracing::error!("Expect revision len {},but receive {}", range_len, records.len());
            }
        }
        Ok(records
            .into_iter()
            .map(|record| record.revision)
            .collect::<Vec<Revision>>())
    }
}

impl<C> RevisionMemoryCacheDelegate for Arc<dyn RevisionDiskCache<C, Error = FlowyError>> {
    fn send_sync(&self, mut records: Vec<SyncRecord>) -> FlowyResult<()> {
        records.retain(|record| record.write_to_disk);
        if !records.is_empty() {
            tracing::Span::current().record(
                "checkpoint_result",
                &format!("{} records were saved", records.len()).as_str(),
            );
            let _ = self.create_revision_records(records)?;
        }
        Ok(())
    }

    fn receive_ack(&self, object_id: &str, rev_id: i64) {
        let changeset = RevisionChangeset {
            object_id: object_id.to_string(),
            rev_id: rev_id.into(),
            state: RevisionState::Ack,
        };
        match self.update_revision_record(vec![changeset]) {
            Ok(_) => {}
            Err(e) => tracing::error!("{}", e),
        }
    }
}

#[derive(Default)]
struct DeferSyncSequence {
    rev_ids: VecDeque<i64>,
    start: Option<usize>,
    step: usize,
}

impl DeferSyncSequence {
    fn new() -> Self {
        DeferSyncSequence::default()
    }

    fn push(&mut self, new_rev_id: i64) -> FlowyResult<()> {
        let _ = self.dry_push(new_rev_id)?;

        self.step += 1;
        if self.start.is_none() && !self.rev_ids.is_empty() {
            self.start = Some(self.rev_ids.len() - 1);
        }
        Ok(())
    }

    fn dry_push(&mut self, new_rev_id: i64) -> FlowyResult<()> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.rev_ids.back() {
            if *rev_id >= new_rev_id {
                return Err(
                    FlowyError::internal().context(format!("The new revision's id must be greater than {}", rev_id))
                );
            }
        }
        self.rev_ids.push_back(new_rev_id);
        Ok(())
    }

    fn ack(&mut self, rev_id: &i64) -> FlowyResult<()> {
        let cur_rev_id = self.rev_ids.front().cloned();
        if let Some(pop_rev_id) = cur_rev_id {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                return Err(FlowyError::internal().context(desc));
            }
            let _ = self.rev_ids.pop_front();
        }
        Ok(())
    }

    fn next_rev_id(&self) -> Option<i64> {
        self.rev_ids.front().cloned()
    }

    fn clear(&mut self) {
        self.start = None;
        self.step = 0;
        self.rev_ids.clear();
    }

    // Compact the rev_ids into one except the current synchronizing rev_id.
    fn compact(&mut self) -> VecDeque<i64> {
        if self.start.is_none() {
            return VecDeque::default();
        }

        let start = self.start.unwrap();
        let compact_seq = self.rev_ids.split_off(start);
        self.start = None;
        self.step = 0;
        compact_seq

        // let mut new_seq = self.rev_ids.clone();
        // let mut drained = new_seq.drain(1..).collect::<VecDeque<_>>();
        //
        // let start = drained.pop_front()?;
        // let end = drained.pop_back().unwrap_or(start);
        // Some((RevisionRange { start, end }, new_seq))
    }
}
