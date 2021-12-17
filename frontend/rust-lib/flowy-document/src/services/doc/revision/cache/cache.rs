use crate::{
    errors::FlowyError,
    services::doc::revision::{
        cache::{
            disk::{Persistence, RevisionDiskCache},
            memory::{RevisionMemoryCache, RevisionMemoryCacheMissing},
            sync::RevisionSyncSeq,
        },
        RevisionRecord,
    },
};

use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::{
    core::Operation,
    revision::{RevState, Revision, RevisionRange},
    rich_text::RichTextDelta,
};
use std::sync::Arc;
use tokio::{
    sync::RwLock,
    task::{spawn_blocking, JoinHandle},
};

type DocRevisionDiskCache = dyn RevisionDiskCache<Error = FlowyError>;

pub struct RevisionCache {
    doc_id: String,
    pub disk_cache: Arc<DocRevisionDiskCache>,
    memory_cache: Arc<RevisionMemoryCache>,
    sync_seq: Arc<RevisionSyncSeq>,
    defer_save: RwLock<Option<JoinHandle<()>>>,
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
            defer_save: RwLock::new(None),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_local_revision(&self, revision: Revision) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(FlowyError::internal().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }
        let record = RevisionRecord {
            revision,
            state: RevState::StateLocal,
        };
        let _ = self.memory_cache.add_revision(&record).await;
        self.sync_seq.add_revision(record).await?;
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_remote_revision(&self, revision: Revision) -> FlowyResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(FlowyError::internal().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }
        let record = RevisionRecord {
            revision,
            state: RevState::StateLocal,
        };
        self.memory_cache.add_revision(&record).await;
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), fields(rev_id = %rev_id))]
    pub async fn ack_revision(&self, rev_id: i64) {
        self.sync_seq.ack_revision(&rev_id).await;
        self.save_revisions().await;
    }

    pub async fn get_revision(&self, _doc_id: &str, rev_id: i64) -> Option<RevisionRecord> {
        self.memory_cache.get_revision(&rev_id).await
    }

    async fn save_revisions(&self) {
        // https://github.com/async-graphql/async-graphql/blob/ed8449beec3d9c54b94da39bab33cec809903953/src/dataloader/mod.rs#L362
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        // if self.sync_seq.is_empty() {
        //     return;
        // }

        // let memory_cache = self.sync_seq.clone();
        // let disk_cache = self.disk_cache.clone();
        // *self.defer_save.write().await = Some(tokio::spawn(async move {
        //     tokio::time::sleep(Duration::from_millis(300)).await;
        //     let (ids, records) = memory_cache.revisions();
        //     match disk_cache.create_revisions(records) {
        //         Ok(_) => {
        //             memory_cache.remove_revisions(ids);
        //         },
        //         Err(e) => log::error!("Save revision failed: {:?}", e),
        //     }
        // }));
    }

    pub async fn revisions_in_range(&self, range: RevisionRange) -> FlowyResult<Vec<Revision>> {
        let records = self.memory_cache.get_revisions_in_range(&range).await?;
        Ok(records
            .into_iter()
            .map(|record| record.revision)
            .collect::<Vec<Revision>>())
    }

    pub(crate) fn next_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
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

impl RevisionMemoryCacheMissing for Arc<Persistence> {
    fn get_revision_record(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, FlowyError> {
        match self.read_revision(&doc_id, rev_id)? {
            None => {
                tracing::warn!("Can't find revision in {} with rev_id: {}", doc_id, rev_id);
                Ok(None)
            },
            Some(record) => Ok(Some(record)),
        }
    }

    fn get_revision_records_with_range(
        &self,
        doc_id: &str,
        range: RevisionRange,
    ) -> FutureResult<Vec<RevisionRecord>, FlowyError> {
        let disk_cache = self.clone();
        let doc_id = doc_id.to_owned();
        FutureResult::new(async move {
            let records = spawn_blocking(move || disk_cache.revisions_in_range(&doc_id, &range))
                .await
                .map_err(internal_error)??;

            Ok::<Vec<RevisionRecord>, FlowyError>(records)
        })
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionCache {
    pub fn disk_cache(&self) -> Arc<DocRevisionDiskCache> { self.disk_cache.clone() }

    pub fn memory_cache(&self) -> Arc<RevisionSyncSeq> { self.sync_seq.clone() }
}
