use crate::{
    errors::FlowyError,
    services::doc::{revision::RevisionCache, RevisionRecord},
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    entities::{
        doc::DocumentInfo,
        revision::{RepeatedRevision, Revision, RevisionRange, RevisionState},
    },
    util::{md5, pair_rev_id_from_revisions, RevIdCounter},
};
use flowy_error::FlowyResult;
use futures_util::{future, stream, stream::StreamExt};
use lib_infra::future::FutureResult;
use lib_ot::{
    core::{Operation, OperationTransformable},
    errors::OTError,
    rich_text::RichTextDelta,
};
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::RwLock;

pub trait RevisionServer: Send + Sync {
    fn fetch_document(&self, doc_id: &str) -> FutureResult<DocumentInfo, FlowyError>;
}

pub struct RevisionManager {
    pub(crate) doc_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    cache: Arc<RevisionCache>,
    sync_seq: Arc<RevisionSyncSequence>,
}

impl RevisionManager {
    pub fn new(user_id: &str, doc_id: &str, cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        let sync_seq = Arc::new(RevisionSyncSequence::new());
        Self {
            doc_id: doc_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            cache,
            sync_seq,
        }
    }

    pub async fn load_document(&mut self, server: Arc<dyn RevisionServer>) -> FlowyResult<RichTextDelta> {
        let revisions = RevisionLoader {
            doc_id: self.doc_id.clone(),
            user_id: self.user_id.clone(),
            server,
            cache: self.cache.clone(),
        }
        .load()
        .await?;
        let doc = mk_doc_from_revisions(&self.doc_id, revisions)?;
        self.rev_id_counter.set(doc.rev_id);
        Ok(doc.delta()?)
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), err)]
    pub async fn reset_document(&self, revisions: RepeatedRevision) -> FlowyResult<()> {
        let rev_id = pair_rev_id_from_revisions(&revisions).1;
        let _ = self.cache.reset_document(&self.doc_id, revisions.into_inner()).await?;
        self.rev_id_counter.set(rev_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }
        self.rev_id_counter.set(revision.rev_id);
        let _ = self.cache.add(revision.clone(), RevisionState::Ack, true).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_local_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        if revision.delta_data.is_empty() {
            return Err(FlowyError::internal().context("Delta data should be empty"));
        }

        let record = self.cache.add(revision.clone(), RevisionState::Local, true).await?;
        self.sync_seq.add_revision(record).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        if self.sync_seq.ack(&rev_id).await.is_ok() {
            self.cache.ack(rev_id).await;
        }
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn set_rev_id(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub fn next_rev_id_pair(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub async fn get_revisions_in_range(&self, range: RevisionRange) -> Result<Vec<Revision>, FlowyError> {
        debug_assert!(range.doc_id == self.doc_id);
        let revisions = self.cache.revisions_in_range(range.clone()).await?;
        Ok(revisions)
    }

    pub fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> {
        let sync_seq = self.sync_seq.clone();
        let cache = self.cache.clone();
        FutureResult::new(async move {
            match sync_seq.next_sync_revision().await {
                None => match sync_seq.next_sync_rev_id().await {
                    None => Ok(None),
                    Some(rev_id) => Ok(cache.get(rev_id).await.map(|record| record.revision)),
                },
                Some((_, record)) => Ok(Some(record.revision)),
            }
        })
    }

    pub async fn latest_revision(&self) -> Revision { self.cache.latest_revision().await }

    pub async fn get_revision(&self, rev_id: i64) -> Option<Revision> {
        self.cache.get(rev_id).await.map(|record| record.revision)
    }
}

struct RevisionSyncSequence {
    revs_map: Arc<DashMap<i64, RevisionRecord>>,
    local_revs: Arc<RwLock<VecDeque<i64>>>,
}

impl std::default::Default for RevisionSyncSequence {
    fn default() -> Self {
        let local_revs = Arc::new(RwLock::new(VecDeque::new()));
        RevisionSyncSequence {
            revs_map: Arc::new(DashMap::new()),
            local_revs,
        }
    }
}

impl RevisionSyncSequence {
    fn new() -> Self { RevisionSyncSequence::default() }

    async fn add_revision(&self, record: RevisionRecord) -> Result<(), OTError> {
        // The last revision's rev_id must be greater than the new one.
        if let Some(rev_id) = self.local_revs.read().await.back() {
            if *rev_id >= record.revision.rev_id {
                return Err(OTError::revision_id_conflict()
                    .context(format!("The new revision's id must be greater than {}", rev_id)));
            }
        }
        self.local_revs.write().await.push_back(record.revision.rev_id);
        self.revs_map.insert(record.revision.rev_id, record);
        Ok(())
    }

    async fn ack(&self, rev_id: &i64) -> FlowyResult<()> {
        if let Some(pop_rev_id) = self.next_sync_rev_id().await {
            if &pop_rev_id != rev_id {
                let desc = format!(
                    "The ack rev_id:{} is not equal to the current rev_id:{}",
                    rev_id, pop_rev_id
                );
                // tracing::error!("{}", desc);
                return Err(FlowyError::internal().context(desc));
            }

            tracing::debug!("pop revision {}", pop_rev_id);
            self.revs_map.remove(&pop_rev_id);
            let _ = self.local_revs.write().await.pop_front();
        }
        Ok(())
    }

    async fn next_sync_revision(&self) -> Option<(i64, RevisionRecord)> {
        match self.local_revs.read().await.front() {
            None => None,
            Some(rev_id) => self.revs_map.get(rev_id).map(|r| (*r.key(), r.value().clone())),
        }
    }

    async fn next_sync_rev_id(&self) -> Option<i64> { self.local_revs.read().await.front().copied() }
}

struct RevisionLoader {
    doc_id: String,
    user_id: String,
    server: Arc<dyn RevisionServer>,
    cache: Arc<RevisionCache>,
}

impl RevisionLoader {
    async fn load(&self) -> Result<Vec<Revision>, FlowyError> {
        let records = self.cache.batch_get(&self.doc_id)?;
        let revisions: Vec<Revision>;
        if records.is_empty() {
            let doc = self.server.fetch_document(&self.doc_id).await?;
            let delta_data = Bytes::from(doc.text.clone());
            let doc_md5 = md5(&delta_data);
            let revision = Revision::new(
                &doc.doc_id,
                doc.base_rev_id,
                doc.rev_id,
                delta_data,
                &self.user_id,
                doc_md5,
            );
            let _ = self.cache.add(revision.clone(), RevisionState::Ack, true).await?;
            revisions = vec![revision];
        } else {
            // Sync the records if their state is RevisionState::Local.
            stream::iter(records.clone())
                .filter(|record| future::ready(record.state == RevisionState::Local))
                .for_each(|record| async move {
                    match self.cache.add(record.revision, record.state, false).await {
                        Ok(_) => {},
                        Err(e) => tracing::error!("{}", e),
                    }
                })
                .await;
            revisions = records.into_iter().map(|record| record.revision).collect::<_>();
        }

        Ok(revisions)
    }
}

fn mk_doc_from_revisions(doc_id: &str, revisions: Vec<Revision>) -> FlowyResult<DocumentInfo> {
    let (base_rev_id, rev_id) = revisions.last().unwrap().pair_rev_id();
    let mut delta = RichTextDelta::new();
    for (_, revision) in revisions.into_iter().enumerate() {
        match RichTextDelta::from_bytes(revision.delta_data) {
            Ok(local_delta) => {
                delta = delta.compose(&local_delta)?;
            },
            Err(e) => {
                tracing::error!("Deserialize delta from revision failed: {}", e);
            },
        }
    }
    correct_delta_if_need(&mut delta);

    Result::<DocumentInfo, FlowyError>::Ok(DocumentInfo {
        doc_id: doc_id.to_owned(),
        text: delta.to_json(),
        rev_id,
        base_rev_id,
    })
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

#[cfg(feature = "flowy_unit_test")]
impl RevisionSyncSequence {
    #[allow(dead_code)]
    pub fn revs_map(&self) -> Arc<DashMap<i64, RevisionRecord>> { self.revs_map.clone() }
    #[allow(dead_code)]
    pub fn pending_revs(&self) -> Arc<RwLock<VecDeque<i64>>> { self.local_revs.clone() }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub fn revision_cache(&self) -> Arc<RevisionCache> { self.cache.clone() }
}
