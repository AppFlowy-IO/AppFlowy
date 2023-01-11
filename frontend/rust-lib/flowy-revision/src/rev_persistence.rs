use crate::cache::{
    disk::{RevisionChangeset, RevisionDiskCache},
    memory::RevisionMemoryCacheDelegate,
};
use crate::disk::{RevisionState, SyncRecord};
use crate::memory::RevisionMemoryCache;
use crate::RevisionMergeable;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_http_model::revision::{Revision, RevisionRange};
use std::collections::{HashMap, VecDeque};

use std::{borrow::Cow, sync::Arc};
use tokio::sync::RwLock;
use tokio::task::spawn_blocking;

pub const REVISION_WRITE_INTERVAL_IN_MILLIS: u64 = 600;

#[derive(Clone)]
pub struct RevisionPersistenceConfiguration {
    // If the number of revisions that didn't sync to the server greater than the merge_threshold
    // then these revisions will be merged into one revision.
    merge_threshold: usize,

    /// Indicates that the revisions that didn't sync to the server can be merged into one when
    /// `compact_lagging_revisions` get called.
    merge_lagging: bool,
}

impl RevisionPersistenceConfiguration {
    pub fn new(merge_threshold: usize, merge_lagging: bool) -> Self {
        debug_assert!(merge_threshold > 1);
        if merge_threshold > 1 {
            Self {
                merge_threshold,
                merge_lagging,
            }
        } else {
            Self {
                merge_threshold: 100,
                merge_lagging,
            }
        }
    }
}

impl std::default::Default for RevisionPersistenceConfiguration {
    fn default() -> Self {
        Self {
            merge_threshold: 100,
            merge_lagging: false,
        }
    }
}

/// Represents as the persistence of revisions including memory or disk cache.
/// The generic parameter, `Connection`, represents as the disk backend's connection.
/// If the backend is SQLite, then the Connect will be SQLiteConnect.
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

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn compact_lagging_revisions<'a>(
        &'a self,
        rev_compress: &Arc<dyn RevisionMergeable + 'a>,
    ) -> FlowyResult<()> {
        if !self.configuration.merge_lagging {
            return Ok(());
        }

        let mut sync_seq = self.sync_seq.write().await;
        let compact_seq = sync_seq.compact();
        if !compact_seq.is_empty() {
            let range = RevisionRange {
                start: *compact_seq.front().unwrap(),
                end: *compact_seq.back().unwrap(),
            };

            let revisions = self.revisions_in_range(&range).await?;
            let rev_ids = range.to_rev_ids();
            debug_assert_eq!(range.len() as usize, revisions.len());
            // compact multiple revisions into one
            let merged_revision = rev_compress.merge_revisions(&self.user_id, &self.object_id, revisions)?;
            tracing::Span::current().record("rev_id", &merged_revision.rev_id);

            let record = SyncRecord {
                revision: merged_revision,
                state: RevisionState::Sync,
                write_to_disk: true,
            };
            self.disk_cache
                .delete_and_insert_records(&self.object_id, Some(rev_ids), vec![record])?;
        }
        Ok(())
    }

    /// Sync the each records' revisions to remote if its state is `RevisionState::Sync`.
    ///
    pub(crate) async fn sync_revision_records(&self, records: &[SyncRecord]) -> FlowyResult<()> {
        let mut sync_seq = self.sync_seq.write().await;
        for record in records {
            if record.state == RevisionState::Sync {
                self.add(record.revision.clone(), RevisionState::Sync, false).await?;
                sync_seq.recv(record.revision.rev_id)?; // Sync the records if their state is RevisionState::Sync.
            }
        }
        Ok(())
    }

    /// Save the revision to disk and append it to the end of the sync sequence.
    /// The returned value,rev_id, will be different with the passed-in revision's rev_id if
    /// multiple revisions are merged into one.
    #[tracing::instrument(level = "trace", skip_all, fields(rev_id, compact_range, object_id=%self.object_id), err)]
    pub(crate) async fn add_local_revision<'a>(
        &'a self,
        new_revision: Revision,
        rev_compress: &Arc<dyn RevisionMergeable + 'a>,
    ) -> FlowyResult<i64> {
        let mut sync_seq = self.sync_seq.write().await;

        // Before the new_revision is pushed into the sync_seq, we check if the current `compact_length` of the
        // sync_seq is less equal to or greater than the merge threshold. If yes, it's needs to merged
        // with the new_revision into one revision.
        let mut compact_seq = VecDeque::default();
        // tracing::info!("{}", compact_seq)
        if sync_seq.compact_length >= self.configuration.merge_threshold - 1 {
            compact_seq.extend(sync_seq.compact());
        }
        if !compact_seq.is_empty() {
            let range = RevisionRange {
                start: *compact_seq.front().unwrap(),
                end: *compact_seq.back().unwrap(),
            };

            tracing::Span::current().record("compact_range", &format!("{}", range).as_str());
            let mut revisions = self.revisions_in_range(&range).await?;
            debug_assert_eq!(range.len() as usize, revisions.len());
            // append the new revision
            revisions.push(new_revision);

            // compact multiple revisions into one
            let merged_revision = rev_compress.merge_revisions(&self.user_id, &self.object_id, revisions)?;
            let rev_id = merged_revision.rev_id;
            tracing::Span::current().record("rev_id", &merged_revision.rev_id);
            sync_seq.recv(merged_revision.rev_id)?;

            // replace the revisions in range with compact revision
            self.compact(&range, merged_revision).await?;
            Ok(rev_id)
        } else {
            let rev_id = new_revision.rev_id;
            tracing::Span::current().record("rev_id", &rev_id);
            self.add(new_revision, RevisionState::Sync, true).await?;
            sync_seq.merge_recv(rev_id)?;
            Ok(rev_id)
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

    pub(crate) fn number_of_records_in_disk(&self) -> usize {
        match self.disk_cache.read_revision_records(&self.object_id, None) {
            Ok(records) => records.len(),
            Err(e) => {
                tracing::error!("Read revision records failed: {:?}", e);
                0
            }
        }
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

        self.disk_cache
            .delete_and_insert_records(&self.object_id, None, records.clone())?;
        self.memory_cache.reset_with_revisions(records).await;
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
        self.disk_cache
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

    pub fn load_all_records(&self, object_id: &str) -> FlowyResult<Vec<SyncRecord>> {
        let mut record_ids = HashMap::new();
        let mut records = vec![];
        for record in self.disk_cache.read_revision_records(object_id, None)? {
            let rev_id = record.revision.rev_id;
            if record_ids.get(&rev_id).is_none() {
                records.push(record);
            }
            record_ids.insert(rev_id, rev_id);
        }
        Ok(records)
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
                tracing::error!("Expect revision len {},but receive {}", range_len, records.len());
            }
        }
        Ok(records
            .into_iter()
            .map(|record| record.revision)
            .collect::<Vec<Revision>>())
    }

    #[allow(dead_code)]
    pub fn delete_revisions_from_range(&self, range: RevisionRange) -> FlowyResult<()> {
        self.disk_cache
            .delete_revision_records(&self.object_id, Some(range.to_rev_ids()))?;
        Ok(())
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
            self.create_revision_records(records)?;
        }
        Ok(())
    }

    fn receive_ack(&self, object_id: &str, rev_id: i64) {
        let changeset = RevisionChangeset {
            object_id: object_id.to_string(),
            rev_id,
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
    compact_index: Option<usize>,
    compact_length: usize,
}

impl DeferSyncSequence {
    fn new() -> Self {
        DeferSyncSequence::default()
    }

    /// Pushes the new_rev_id to the end of the list and marks this new_rev_id is mergeable.
    ///
    /// When calling `compact` method, it will return a list of revision ids started from
    /// the `compact_start_pos`, and ends with the `compact_length`.
    fn merge_recv(&mut self, new_rev_id: i64) -> FlowyResult<()> {
        self.recv(new_rev_id)?;

        self.compact_length += 1;
        if self.compact_index.is_none() && !self.rev_ids.is_empty() {
            self.compact_index = Some(self.rev_ids.len() - 1);
        }
        Ok(())
    }

    /// Pushes the new_rev_id to the end of the list.
    fn recv(&mut self, new_rev_id: i64) -> FlowyResult<()> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.rev_ids.back() {
            if *rev_id >= new_rev_id {
                tracing::error!("The new revision's id must be greater than {}", rev_id);
                return Ok(());
            }
        }
        self.rev_ids.push_back(new_rev_id);
        Ok(())
    }

    /// Removes the rev_id from the list
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

            let mut compact_rev_id = None;
            if let Some(compact_index) = self.compact_index {
                compact_rev_id = self.rev_ids.get(compact_index).cloned();
            }

            let pop_rev_id = self.rev_ids.pop_front();
            if let (Some(compact_rev_id), Some(pop_rev_id)) = (compact_rev_id, pop_rev_id) {
                if compact_rev_id <= pop_rev_id && self.compact_length > 0 {
                    self.compact_length -= 1;
                }
            }
        }
        Ok(())
    }

    fn next_rev_id(&self) -> Option<i64> {
        self.rev_ids.front().cloned()
    }

    fn clear(&mut self) {
        self.compact_index = None;
        self.compact_length = 0;
        self.rev_ids.clear();
    }

    // Compact the rev_ids into one except the current synchronizing rev_id.
    fn compact(&mut self) -> VecDeque<i64> {
        let mut compact_seq = VecDeque::with_capacity(self.rev_ids.len());
        if let Some(start) = self.compact_index {
            if start < self.rev_ids.len() {
                let seq = self.rev_ids.split_off(start);
                compact_seq.extend(seq);
            }
        }
        self.compact_index = None;
        self.compact_length = 0;
        compact_seq
    }
}
