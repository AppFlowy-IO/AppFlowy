use crate::{
    core::revision::{
        disk::{DocumentRevisionDiskCache, RevisionChangeset, RevisionTableState, SQLitePersistence},
        memory::{DocumentRevisionMemoryCache, RevisionMemoryCacheDelegate},
    },
    errors::FlowyError,
};
use flowy_collaboration::entities::revision::{Revision, RevisionRange, RevisionState};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use std::{
    borrow::Cow,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
};
use tokio::task::spawn_blocking;

pub struct DocumentRevisionCache {
    doc_id: String,
    disk_cache: Arc<dyn DocumentRevisionDiskCache<Error = FlowyError>>,
    memory_cache: Arc<DocumentRevisionMemoryCache>,
    latest_rev_id: AtomicI64,
}

impl DocumentRevisionCache {
    pub fn new(user_id: &str, doc_id: &str, pool: Arc<ConnectionPool>) -> DocumentRevisionCache {
        let disk_cache = Arc::new(SQLitePersistence::new(user_id, pool));
        let memory_cache = Arc::new(DocumentRevisionMemoryCache::new(doc_id, Arc::new(disk_cache.clone())));
        let doc_id = doc_id.to_owned();
        Self {
            doc_id,
            disk_cache,
            memory_cache,
            latest_rev_id: AtomicI64::new(0),
        }
    }

    pub async fn add(
        &self,
        revision: Revision,
        state: RevisionState,
        write_to_disk: bool,
    ) -> FlowyResult<RevisionRecord> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(FlowyError::internal().context(format!("Duplicate revision: {} {:?}", revision.rev_id, state)));
        }
        let state = state.as_ref().clone();
        let rev_id = revision.rev_id;
        let record = RevisionRecord {
            revision,
            state,
            write_to_disk,
        };

        self.memory_cache.add(Cow::Borrowed(&record)).await;
        self.set_latest_rev_id(rev_id);
        Ok(record)
    }

    pub async fn ack(&self, rev_id: i64) {
        self.memory_cache.ack(&rev_id).await;
    }

    pub async fn get(&self, rev_id: i64) -> Option<RevisionRecord> {
        match self.memory_cache.get(&rev_id).await {
            None => match self.disk_cache.read_revision_records(&self.doc_id, Some(vec![rev_id])) {
                Ok(mut records) => {
                    if !records.is_empty() {
                        assert_eq!(records.len(), 1);
                    }
                    records.pop()
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

    pub async fn latest_revision(&self) -> Revision {
        let rev_id = self.latest_rev_id.load(SeqCst);
        self.get(rev_id).await.unwrap().revision
    }

    pub async fn revisions_in_range(&self, range: RevisionRange) -> FlowyResult<Vec<Revision>> {
        let mut records = self.memory_cache.get_with_range(&range).await?;
        let range_len = range.len() as usize;
        if records.len() != range_len {
            let disk_cache = self.disk_cache.clone();
            let doc_id = self.doc_id.clone();
            records = spawn_blocking(move || disk_cache.read_revision_records_with_range(&doc_id, &range))
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

    #[tracing::instrument(level = "debug", skip(self, doc_id, revisions))]
    pub async fn reset_with_revisions(&self, doc_id: &str, revisions: Vec<Revision>) -> FlowyResult<()> {
        let revision_records = revisions
            .to_vec()
            .into_iter()
            .map(|revision| RevisionRecord {
                revision,
                state: RevisionState::Local,
                write_to_disk: false,
            })
            .collect::<Vec<_>>();

        let _ = self.memory_cache.reset_with_revisions(&revision_records).await?;
        let _ = self.disk_cache.reset_document(doc_id, revision_records)?;
        Ok(())
    }

    #[inline]
    fn set_latest_rev_id(&self, rev_id: i64) {
        let _ = self.latest_rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
    }
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
            let _ = self.write_revision_records(records, conn)?;
        }
        Ok(())
    }

    fn receive_ack(&self, doc_id: &str, rev_id: i64) {
        let changeset = RevisionChangeset {
            doc_id: doc_id.to_string(),
            rev_id: rev_id.into(),
            state: RevisionTableState::Ack,
        };
        match self.update_revision_record(vec![changeset]) {
            Ok(_) => {}
            Err(e) => tracing::error!("{}", e),
        }
    }
}

#[derive(Clone)]
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
