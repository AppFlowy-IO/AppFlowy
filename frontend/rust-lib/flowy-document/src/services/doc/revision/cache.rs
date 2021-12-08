use crate::{
    errors::{internal_error, DocError, DocResult},
    services::doc::revision::RevisionServer,
    sql_tables::RevTableSql,
};
use flowy_database::ConnectionPool;
use flowy_document_infra::entities::doc::Doc;
use lib_infra::future::ResultFuture;
use lib_ot::{
    core::{Operation, OperationTransformable},
    revision::{
        RevId,
        RevState,
        RevType,
        Revision,
        RevisionDiskCache,
        RevisionMemoryCache,
        RevisionRange,
        RevisionRecord,
    },
    rich_text::RichTextDelta,
};
use std::{sync::Arc, time::Duration};
use tokio::{
    sync::RwLock,
    task::{spawn_blocking, JoinHandle},
};

pub trait RevisionIterator: Send + Sync {
    fn next(&self) -> ResultFuture<Option<RevisionRecord>, DocError>;
}

type DocRevisionDeskCache = dyn RevisionDiskCache<Error = DocError>;

pub struct RevisionCache {
    doc_id: String,
    dish_cache: Arc<DocRevisionDeskCache>,
    memory_cache: Arc<RevisionMemoryCache>,
    defer_save: RwLock<Option<JoinHandle<()>>>,
    server: Arc<dyn RevisionServer>,
}

impl RevisionCache {
    pub fn new(doc_id: &str, pool: Arc<ConnectionPool>, server: Arc<dyn RevisionServer>) -> RevisionCache {
        let doc_id = doc_id.to_owned();
        let dish_cache = Arc::new(Persistence::new(pool));
        let memory_cache = Arc::new(RevisionMemoryCache::new());
        Self {
            doc_id,
            dish_cache,
            memory_cache,
            defer_save: RwLock::new(None),
            server,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_revision(&self, revision: Revision) -> DocResult<()> {
        if self.memory_cache.contains(&revision.rev_id) {
            return Err(DocError::duplicate_rev().context(format!("Duplicate revision id: {}", revision.rev_id)));
        }
        self.memory_cache.add_revision(revision.clone()).await?;
        self.save_revisions().await;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), fields(rev_id = %rev_id.as_ref()))]
    pub async fn ack_revision(&self, rev_id: RevId) {
        let rev_id = rev_id.value;
        self.memory_cache.mut_revision(&rev_id, |mut rev| rev.value_mut().ack());
        self.save_revisions().await;
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

    pub async fn revisions_in_range(&self, range: RevisionRange) -> DocResult<Vec<Revision>> {
        let revs = self.memory_cache.revisions_in_range(&range).await?;
        if revs.len() == range.len() as usize {
            Ok(revs)
        } else {
            let doc_id = self.doc_id.clone();
            let disk_cache = self.dish_cache.clone();
            spawn_blocking(move || disk_cache.revisions_in_range(&doc_id, &range))
                .await
                .map_err(internal_error)?
        }
    }

    pub async fn fetch_document(&self) -> DocResult<Doc> {
        let result = fetch_from_local(&self.doc_id, self.dish_cache.clone()).await;
        if result.is_ok() {
            return result;
        }

        let doc = self.server.fetch_document_from_remote(&self.doc_id).await?;
        let delta_data = doc.data.as_bytes();
        let revision = Revision::new(
            doc.base_rev_id,
            doc.rev_id,
            delta_data.to_owned(),
            &doc.id,
            RevType::Remote,
        );
        let record = RevisionRecord {
            revision,
            state: RevState::Acked,
        };
        let _ = self.dish_cache.create_revisions(vec![record])?;
        Ok(doc)
    }
}

impl RevisionIterator for RevisionCache {
    fn next(&self) -> ResultFuture<Option<RevisionRecord>, DocError> {
        let memory_cache = self.memory_cache.clone();
        let disk_cache = self.dish_cache.clone();
        let doc_id = self.doc_id.clone();
        ResultFuture::new(async move {
            match memory_cache.front_revision().await {
                None => {
                    //
                    match memory_cache.front_rev_id().await {
                        None => Ok(None),
                        Some(rev_id) => match disk_cache.read_revision(&doc_id, rev_id)? {
                            None => Ok(None),
                            Some(revision) => Ok(Some(RevisionRecord::new(revision))),
                        },
                    }
                },
                Some((_, record)) => Ok(Some(record)),
            }
        })
    }
}

async fn fetch_from_local(doc_id: &str, disk_cache: Arc<DocRevisionDeskCache>) -> DocResult<Doc> {
    let doc_id = doc_id.to_owned();
    spawn_blocking(move || {
        let revisions = disk_cache.read_revisions(&doc_id)?;
        if revisions.is_empty() {
            return Err(DocError::record_not_found().context("Local doesn't have this document"));
        }

        let base_rev_id: RevId = revisions.last().unwrap().base_rev_id.into();
        let rev_id: RevId = revisions.last().unwrap().rev_id.into();
        let mut delta = RichTextDelta::new();
        for (_, revision) in revisions.into_iter().enumerate() {
            match RichTextDelta::from_bytes(revision.delta_data) {
                Ok(local_delta) => {
                    delta = delta.compose(&local_delta)?;
                },
                Err(e) => {
                    log::error!("Deserialize delta from revision failed: {}", e);
                },
            }
        }

        #[cfg(debug_assertions)]
        validate_delta(&doc_id, disk_cache, &delta);

        match delta.ops.last() {
            None => {},
            Some(op) => {
                let data = op.get_data();
                if !data.ends_with('\n') {
                    delta.ops.push(Operation::Insert("\n".into()))
                }
            },
        }

        Result::<Doc, DocError>::Ok(Doc {
            id: doc_id,
            data: delta.to_json(),
            rev_id: rev_id.into(),
            base_rev_id: base_rev_id.into(),
        })
    })
    .await
    .map_err(internal_error)?
}

#[cfg(debug_assertions)]
fn validate_delta(doc_id: &str, disk_cache: Arc<DocRevisionDeskCache>, delta: &RichTextDelta) {
    if delta.ops.last().is_none() {
        return;
    }

    let data = delta.ops.last().as_ref().unwrap().get_data();
    if !data.ends_with('\n') {
        log::error!("The op must end with newline");
        let result = || {
            let revisions = disk_cache.read_revisions(&doc_id)?;
            for revision in revisions {
                let delta = RichTextDelta::from_bytes(revision.delta_data)?;
                log::error!("Invalid revision: {}:{}", revision.rev_id, delta.to_json());
            }
            Ok::<(), DocError>(())
        };
        match result() {
            Ok(_) => {},
            Err(e) => log::error!("{}", e),
        }
    }
}

pub(crate) struct Persistence {
    pub(crate) pool: Arc<ConnectionPool>,
}

impl RevisionDiskCache for Persistence {
    type Error = DocError;

    fn create_revisions(&self, revisions: Vec<RevisionRecord>) -> Result<(), Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, DocError, _>(|| {
            let _ = RevTableSql::create_rev_table(revisions, conn)?;
            Ok(())
        })
    }

    fn revisions_in_range(&self, doc_id: &str, range: &RevisionRange) -> Result<Vec<Revision>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error).unwrap();
        let revisions = RevTableSql::read_rev_tables_with_range(doc_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn read_revision(&self, doc_id: &str, rev_id: i64) -> Result<Option<Revision>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_table(doc_id, &rev_id, &*conn)?;
        Ok(some)
    }

    fn read_revisions(&self, doc_id: &str) -> Result<Vec<Revision>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = RevTableSql::read_rev_tables(doc_id, &*conn)?;
        Ok(some)
    }
}

impl Persistence {
    pub(crate) fn new(pool: Arc<ConnectionPool>) -> Self { Self { pool } }
}
