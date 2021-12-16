use crate::{errors::FlowyError, services::doc::revision::RevisionCache};
use flowy_collaboration::{
    entities::doc::Doc,
    util::{md5, RevIdCounter},
};
use flowy_error::FlowyResult;
use lib_infra::future::FutureResult;
use lib_ot::{
    core::OperationTransformable,
    revision::{RevType, Revision, RevisionRange},
    rich_text::RichTextDelta,
};
use std::sync::Arc;

pub trait RevisionServer: Send + Sync {
    fn fetch_document(&self, doc_id: &str) -> FutureResult<Doc, FlowyError>;
}

pub struct RevisionManager {
    doc_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    cache: Arc<RevisionCache>,
}

impl RevisionManager {
    pub fn new(user_id: &str, doc_id: &str, cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        Self {
            doc_id: doc_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            cache,
        }
    }

    pub async fn load_document(&mut self) -> FlowyResult<RichTextDelta> {
        let doc = self.cache.load_document().await?;
        self.update_rev_id_counter_value(doc.rev_id);
        Ok(doc.delta()?)
    }

    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        let _ = self.cache.add_remote_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn add_local_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        let _ = self.cache.add_local_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        self.cache.ack_revision(rev_id).await;
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn update_rev_id_counter_value(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub async fn mk_revisions(&self, range: RevisionRange) -> Result<Revision, FlowyError> {
        debug_assert!(range.doc_id == self.doc_id);
        let revisions = self.cache.revisions_in_range(range.clone()).await?;
        let mut new_delta = RichTextDelta::new();
        for revision in revisions {
            match RichTextDelta::from_bytes(revision.delta_data) {
                Ok(delta) => {
                    new_delta = new_delta.compose(&delta)?;
                },
                Err(e) => log::error!("{}", e),
            }
        }

        let delta_data = new_delta.to_bytes();
        let md5 = md5(&delta_data);
        let revision = Revision::new(
            &self.doc_id,
            range.start,
            range.end,
            delta_data,
            RevType::Remote,
            &self.user_id,
            md5,
        );

        Ok(revision)
    }

    pub fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> { self.cache.next_revision() }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub fn revision_cache(&self) -> Arc<RevisionCache> { self.cache.clone() }
}
