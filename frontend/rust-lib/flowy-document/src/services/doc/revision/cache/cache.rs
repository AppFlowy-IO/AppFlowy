use crate::{
    errors::FlowyError,
    services::doc::revision::{
        cache::{
            disk::{Persistence, RevisionDiskCache},
            memory::{RevisionMemoryCache, RevisionMemoryCacheDelegate},
            sync::RevisionSyncSeq,
        },
        RevisionRecord,
    },
    sql_tables::{RevChangeset, RevTableState},
};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::revision::{RevState, Revision, RevisionRange};
use std::sync::{
    atomic::{AtomicI64, Ordering::SeqCst},
    Arc,
};
use tokio::task::spawn_blocking;

type DocRevisionDiskCache = dyn RevisionDiskCache<Error = FlowyError>;

pub struct RevisionCache {
    doc_id: String,
    pub disk_cache: Arc<DocRevisionDiskCache>,
    memory_cache: Arc<RevisionMemoryCache>,
    sync_seq: Arc<RevisionSyncSeq>,
    latest_rev_id: AtomicI64,
}

impl RevisionCache {
    pub fn new(user_id: &str, doc_id: &str, pool: Arc<ConnectionPool>) -> RevisionCache {
        let disk_cache = Arc::new(Persistence::new(user_id, pool));
        let memory_cache = Arc::new(RevisionMemoryCache::new(doc_id, Arc::new(disk_cache.clone())));
        let sync_seq = Arc::new(RevisionSyncSeq::new());
        let doc_id = doc_id.to_owned();
        Self {
            doc_id,
            disk_cache,
            memory_cache,
            sync_seq,
            latest_rev_id: AtomicI64::new(0),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_local_revision(&self, revision: Revision) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(FlowyError::internal().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }
        let rev_id = revision.rev_id;
        let record = RevisionRecord {
            revision,
            state: RevState::StateLocal,
        };
        let _ = self.memory_cache.add_revision(&record).await;
        self.sync_seq.add_revision(record).await?;
        let _ = self.latest_rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_remote_revision(&self, revision: Revision) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(FlowyError::internal().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }
        let rev_id = revision.rev_id;
        let record = RevisionRecord {
            revision,
            state: RevState::Acked,
        };
        self.memory_cache.add_revision(&record).await;
        let _ = self.latest_rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), fields(rev_id = %rev_id))]
    pub async fn ack_revision(&self, rev_id: i64) {
        if self.sync_seq.ack_revision(&rev_id).await.is_ok() {
            self.memory_cache.ack_revision(&rev_id).await;
        }
    }

    pub fn latest_rev_id(&self) -> i64 { self.latest_rev_id.load(SeqCst) }

    pub async fn get_revision(&self, doc_id: &str, rev_id: i64) -> Option<RevisionRecord> {
        match self.memory_cache.get_revision(&rev_id).await {
            None => match self.disk_cache.read_revision(&self.doc_id, rev_id) {
                Ok(Some(revision)) => Some(revision),
                Ok(None) => {
                    tracing::warn!("Can't find revision in {} with rev_id: {}", doc_id, rev_id);
                    None
                },
                Err(e) => {
                    tracing::error!("{}", e);
                    None
                },
            },
            Some(revision) => Some(revision),
        }
    }

    pub async fn revisions_in_range(&self, range: RevisionRange) -> FlowyResult<Vec<Revision>> {
        let mut records = self.memory_cache.get_revisions_in_range(&range).await?;
        let range_len = range.len() as usize;
        if records.len() != range_len {
            let disk_cache = self.disk_cache.clone();
            let doc_id = self.doc_id.clone();
            records = spawn_blocking(move || disk_cache.revisions_in_range(&doc_id, &range))
                .await
                .map_err(internal_error)??;

            if records.len() != range_len {
                log::error!("Revisions len is not equal to range required");
            }
        }
        Ok(records
            .into_iter()
            .map(|record| record.revision)
            .collect::<Vec<Revision>>())
    }

    pub(crate) fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
        let sync_seq = self.sync_seq.clone();
        let disk_cache = self.disk_cache.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            match sync_seq.next_sync_revision().await {
                None => match sync_seq.next_sync_rev_id().await {
                    None => Ok(None),
                    Some(rev_id) => match disk_cache.read_revision(&doc_id, rev_id)? {
                        None => Ok(None),
                        Some(record) => Ok(Some(record.revision)),
                    },
                },
                Some((_, record)) => Ok(Some(record.revision)),
            }
        })
    }
}

impl RevisionMemoryCacheDelegate for Arc<Persistence> {
    fn receive_checkpoint(&self, records: Vec<RevisionRecord>) -> FlowyResult<()> { self.create_revisions(records) }

    fn receive_ack(&self, doc_id: &str, rev_id: i64) {
        let changeset = RevChangeset {
            doc_id: doc_id.to_string(),
            rev_id: rev_id.into(),
            state: RevTableState::Acked,
        };
        match self.update_revisions(vec![changeset]) {
            Ok(_) => {},
            Err(e) => tracing::error!("{}", e),
        }
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionCache {
    pub fn disk_cache(&self) -> Arc<DocRevisionDiskCache> { self.disk_cache.clone() }

    pub fn memory_cache(&self) -> Arc<RevisionSyncSeq> { self.sync_seq.clone() }
}
