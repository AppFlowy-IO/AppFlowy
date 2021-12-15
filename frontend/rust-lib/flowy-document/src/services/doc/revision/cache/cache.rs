use crate::{
    errors::FlowyError,
    services::doc::revision::{
        cache::{disk::RevisionDiskCache, memory::RevisionMemoryCache},
        RevisionRecord,
        RevisionServer,
    },
    sql_tables::RevTableSql,
};
use bytes::Bytes;
use flowy_collaboration::{entities::doc::Doc, util::md5};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use lib_infra::future::FutureResult;
use lib_ot::{
    core::{Operation, OperationTransformable},
    revision::{RevState, RevType, Revision, RevisionRange},
    rich_text::RichTextDelta,
};
use std::{sync::Arc, time::Duration};
use tokio::{
    sync::{mpsc, RwLock},
    task::{spawn_blocking, JoinHandle},
};

pub trait RevisionIterator: Send + Sync {
    fn next(&self) -> FutureResult<Option<RevisionRecord>, FlowyError>;
}

type DocRevisionDeskCache = dyn RevisionDiskCache<Error = FlowyError>;

pub struct RevisionCache {
    user_id: String,
    doc_id: String,
    dish_cache: Arc<DocRevisionDeskCache>,
    memory_cache: Arc<RevisionMemoryCache>,
    defer_save: RwLock<Option<JoinHandle<()>>>,
    server: Arc<dyn RevisionServer>,
}

impl RevisionCache {
    pub fn new(
        user_id: &str,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        server: Arc<dyn RevisionServer>,
    ) -> RevisionCache {
        let doc_id = doc_id.to_owned();
        let dish_cache = Arc::new(Persistence::new(user_id, pool));
        let memory_cache = Arc::new(RevisionMemoryCache::new());
        Self {
            user_id: user_id.to_owned(),
            doc_id,
            dish_cache,
            memory_cache,
            defer_save: RwLock::new(None),
            server,
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
        self.memory_cache.add_revision(record).await?;
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
        self.memory_cache.add_revision(record).await?;
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), fields(rev_id = %rev_id))]
    pub async fn ack_revision(&self, rev_id: i64) {
        self.memory_cache.ack_revision(&rev_id).await;
        self.save_revisions().await;
    }

    pub async fn query_revision(&self, doc_id: &str, rev_id: i64) -> Option<RevisionRecord> {
        match self.memory_cache.query_revision(&rev_id).await {
            None => match self.dish_cache.read_revision(doc_id, rev_id) {
                Ok(revision) => revision,
                Err(e) => {
                    log::error!("query_revision error: {:?}", e);
                    None
                },
            },
            Some(record) => Some(record),
        }
    }

    async fn save_revisions(&self) {
        if let Some(handler) = self.defer_save.write().await.take() {
            handler.abort();
        }

        if self.memory_cache.is_empty() {
            return;
        }

        let memory_cache = self.memory_cache.clone();
        let disk_cache = self.dish_cache.clone();
        *self.defer_save.write().await = Some(tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(300)).await;
            let (ids, records) = memory_cache.revisions();
            match disk_cache.create_revisions(records) {
                Ok(_) => {
                    memory_cache.remove_revisions(ids);
                },
                Err(e) => log::error!("Save revision failed: {:?}", e),
            }
        }));
    }

    pub async fn revisions_in_range(&self, range: RevisionRange) -> FlowyResult<Vec<Revision>> {
        let revs = self.memory_cache.revisions_in_range(&range).await?;
        if revs.len() == range.len() as usize {
            Ok(revs)
        } else {
            let doc_id = self.doc_id.clone();
            let disk_cache = self.dish_cache.clone();
            let records = spawn_blocking(move || disk_cache.revisions_in_range(&doc_id, &range))
                .await
                .map_err(internal_error)??;

            let revisions = records
                .into_iter()
                .map(|record| record.revision)
                .collect::<Vec<Revision>>();
            Ok(revisions)
        }
    }

    pub async fn load_document(&self) -> FlowyResult<Doc> {
        // Loading the document from disk and it will be sync with server.
        let result = load_from_disk(&self.doc_id, self.memory_cache.clone(), self.dish_cache.clone()).await;
        if result.is_ok() {
            return result;
        }

        // The document doesn't exist in local. Try load from server
        let doc = self.server.fetch_document(&self.doc_id).await?;
        let delta_data = Bytes::from(doc.data.clone());
        let doc_md5 = md5(&delta_data);
        let revision = Revision::new(
            &doc.id,
            doc.base_rev_id,
            doc.rev_id,
            delta_data,
            RevType::Remote,
            &self.user_id,
            doc_md5,
        );

        self.add_remote_revision(revision).await?;
        Ok(doc)
    }
}

impl RevisionIterator for RevisionCache {
    fn next(&self) -> FutureResult<Option<RevisionRecord>, FlowyError> {
        let memory_cache = self.memory_cache.clone();
        let disk_cache = self.dish_cache.clone();
        let doc_id = self.doc_id.clone();
        FutureResult::new(async move {
            match memory_cache.front_local_revision().await {
                None => match memory_cache.front_local_rev_id().await {
                    None => Ok(None),
                    Some(rev_id) => match disk_cache.read_revision(&doc_id, rev_id)? {
                        None => Ok(None),
                        Some(record) => Ok(Some(record)),
                    },
                },
                Some((_, record)) => Ok(Some(record)),
            }
        })
    }
}

async fn load_from_disk(
    doc_id: &str,
    memory_cache: Arc<RevisionMemoryCache>,
    disk_cache: Arc<DocRevisionDeskCache>,
) -> FlowyResult<Doc> {
    let doc_id = doc_id.to_owned();
    let (tx, mut rx) = mpsc::channel(2);
    let doc = spawn_blocking(move || {
        let records = disk_cache.read_revisions(&doc_id)?;
        if records.is_empty() {
            return Err(FlowyError::record_not_found().context("Local doesn't have this document"));
        }

        let (base_rev_id, rev_id) = records.last().unwrap().revision.pair_rev_id();
        let mut delta = RichTextDelta::new();
        for (_, record) in records.into_iter().enumerate() {
            // Opti: revision's clone may cause memory issues
            match RichTextDelta::from_bytes(record.revision.clone().delta_data) {
                Ok(local_delta) => {
                    delta = delta.compose(&local_delta)?;
                    match tx.blocking_send(record) {
                        Ok(_) => {},
                        Err(e) => tracing::error!("❌Load document from disk error: {}", e),
                    }
                },
                Err(e) => {
                    tracing::error!("Deserialize delta from revision failed: {}", e);
                },
            }
        }

        correct_delta_if_need(&mut delta);
        Result::<Doc, FlowyError>::Ok(Doc {
            id: doc_id,
            data: delta.to_json(),
            rev_id,
            base_rev_id,
        })
    })
    .await
    .map_err(internal_error)?;

    while let Some(record) = rx.recv().await {
        match memory_cache.add_revision(record).await {
            Ok(_) => {},
            Err(e) => log::error!("{:?}", e),
        }
    }
    doc
}

fn correct_delta_if_need(delta: &mut RichTextDelta) {
    if delta.ops.last().is_none() {
        return;
    }

    let data = delta.ops.last().as_ref().unwrap().get_data();
    if !data.ends_with('\n') {
        log::error!("❌The op must end with newline. Correcting it by inserting newline op");
        delta.ops.push(Operation::Insert("\n".into()));
    }
}

pub(crate) struct Persistence {
    user_id: String,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl RevisionDiskCache for Persistence {
    type Error = FlowyError;

    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = RevTableSql::create_rev_table(revisions, conn)?;
            Ok(())
        })
    }

    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error).unwrap();
        let revisions = RevTableSql::read_rev_tables_with_range(&self.user_id, doc_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_table(&self.user_id, doc_id, &rev_id, &*conn)?;
        Ok(some)
    }

    fn read_revisions(&self, doc_id: &str) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_tables(&self.user_id, doc_id, &*conn)?;
        Ok(some)
    }
}

impl Persistence {
    pub(crate) fn new(user_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            pool,
        }
    }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionCache {
    pub fn dish_cache(&self) -> Arc<DocRevisionDeskCache> { self.dish_cache.clone() }

    pub fn memory_cache(&self) -> Arc<RevisionMemoryCache> { self.memory_cache.clone() }
}
