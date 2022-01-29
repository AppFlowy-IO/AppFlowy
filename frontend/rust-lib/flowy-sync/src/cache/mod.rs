mod disk;
mod memory;

use crate::cache::{
    disk::{RevisionChangeset, RevisionDiskCache, RevisionTableState, SQLitePersistence},
    memory::{RevisionMemoryCache, RevisionMemoryCacheDelegate},
};

use flowy_collaboration::entities::revision::{Revision, RevisionRange, RevisionState};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyError, FlowyResult};

use std::{
    borrow::Cow,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
};
use tokio::task::spawn_blocking;

pub const REVISION_WRITE_INTERVAL_IN_MILLIS: u64 = 600;

pub struct RevisionCache {
    object_id: String,
    disk_cache: Arc<dyn RevisionDiskCache<Error = FlowyError>>,
    memory_cache: Arc<RevisionMemoryCache>,
    latest_rev_id: AtomicI64,
}
impl RevisionCache {
    pub fn new(user_id: &str, object_id: &str, pool: Arc<ConnectionPool>) -> RevisionCache {
        let disk_cache = Arc::new(SQLitePersistence::new(user_id, pool));
        let memory_cache = Arc::new(RevisionMemoryCache::new(object_id, Arc::new(disk_cache.clone())));
        let object_id = object_id.to_owned();
        Self {
            object_id,
            disk_cache,
            memory_cache,
            latest_rev_id: AtomicI64::new(0),
        }
    }

    pub async fn add(&self, revision: Revision, state: RevisionState, write_to_disk: bool) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            tracing::warn!("Duplicate revision: {}:{}-{:?}", self.object_id, revision.rev_id, state);
            return Ok(());
        }
        let rev_id = revision.rev_id;
        let record = RevisionRecord {
            revision,
            state,
            write_to_disk,
        };

        self.memory_cache.add(Cow::Owned(record)).await;
        self.set_latest_rev_id(rev_id);
        Ok(())
    }

    pub async fn compact(&self, range: &RevisionRange, new_revision: Revision) -> FlowyResult<()> {
        self.memory_cache.remove_with_range(range);
        let rev_ids = range.to_rev_ids();
        let _ = self
            .disk_cache
            .delete_revision_records(&self.object_id, Some(rev_ids))?;

        self.add(new_revision, RevisionState::Sync, true).await?;
        Ok(())
    }

    pub async fn ack(&self, rev_id: i64) {
        self.memory_cache.ack(&rev_id).await;
    }

    pub async fn get(&self, rev_id: i64) -> Option<RevisionRecord> {
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

    pub fn batch_get(&self, doc_id: &str) -> FlowyResult<Vec<RevisionRecord>> {
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

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_with_revisions(&self, object_id: &str, revisions: Vec<Revision>) -> FlowyResult<()> {
        let records = revisions
            .to_vec()
            .into_iter()
            .map(|revision| RevisionRecord {
                revision,
                state: RevisionState::Sync,
                write_to_disk: false,
            })
            .collect::<Vec<_>>();

        let _ = self
            .disk_cache
            .delete_and_insert_records(object_id, None, records.clone())?;
        let _ = self.memory_cache.reset_with_revisions(records).await;

        Ok(())
    }

    #[inline]
    fn set_latest_rev_id(&self, rev_id: i64) {
        let _ = self.latest_rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
    }
}

pub fn mk_revision_disk_cache(
    user_id: &str,
    pool: Arc<ConnectionPool>,
) -> Arc<dyn RevisionDiskCache<Error = FlowyError>> {
    Arc::new(SQLitePersistence::new(user_id, pool))
}

impl RevisionMemoryCacheDelegate for Arc<SQLitePersistence> {
    #[tracing::instrument(level = "trace", skip(self, records), fields(checkpoint_result), err)]
    fn checkpoint_tick(&self, mut records: Vec<RevisionRecord>) -> FlowyResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        records.retain(|record| record.write_to_disk);
        if !records.is_empty() {
            tracing::Span::current().record(
                "checkpoint_result",
                &format!("{} records were saved", records.len()).as_str(),
            );
            let _ = self.create_revision_records(records, conn)?;
        }
        Ok(())
    }

    fn receive_ack(&self, object_id: &str, rev_id: i64) {
        let changeset = RevisionChangeset {
            object_id: object_id.to_string(),
            rev_id: rev_id.into(),
            state: RevisionTableState::Ack,
        };
        match self.update_revision_record(vec![changeset]) {
            Ok(_) => {}
            Err(e) => tracing::error!("{}", e),
        }
    }
}

#[derive(Clone, Debug)]
pub struct RevisionRecord {
    pub revision: Revision,
    pub state: RevisionState,
    pub write_to_disk: bool,
}

impl RevisionRecord {
    pub fn ack(&mut self) {
        self.state = RevisionState::Ack;
    }
}
