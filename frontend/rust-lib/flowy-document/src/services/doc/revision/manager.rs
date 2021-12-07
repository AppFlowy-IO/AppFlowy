use crate::{
    errors::{DocError, DocResult},
    services::doc::revision::RevisionStore,
};
use flowy_database::ConnectionPool;
use flowy_document_infra::{
    entities::doc::{Doc, RevId, RevType, Revision, RevisionRange},
    util::RevIdCounter,
};
use lib_infra::future::ResultFuture;
use lib_ot::core::{OperationTransformable, RichTextDelta};
use std::sync::Arc;
use tokio::sync::mpsc;

pub trait RevisionServer: Send + Sync {
    fn fetch_document_from_remote(&self, doc_id: &str) -> ResultFuture<Doc, DocError>;
}

pub struct RevisionManager {
    doc_id: String,
    rev_id_counter: RevIdCounter,
    rev_store: Arc<RevisionStore>,
}

impl RevisionManager {
    pub fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        server: Arc<dyn RevisionServer>,
        pending_rev_sender: mpsc::UnboundedSender<Revision>,
    ) -> Self {
        let rev_store = RevisionStore::new(doc_id, pool, server, pending_rev_sender);
        let rev_id_counter = RevIdCounter::new(0);
        Self {
            doc_id: doc_id.to_string(),
            rev_id_counter,
            rev_store,
        }
    }

    pub async fn load_document(&mut self) -> DocResult<RichTextDelta> {
        let doc = self.rev_store.fetch_document().await?;
        self.update_rev_id_counter_value(doc.rev_id);
        Ok(doc.delta()?)
    }

    pub async fn add_revision(&self, revision: &Revision) -> Result<(), DocError> {
        let _ = self.rev_store.add_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn ack_revision(&self, rev_id: RevId) -> Result<(), DocError> {
        self.rev_store.ack_revision(rev_id).await;
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn update_rev_id_counter_value(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub async fn mk_revisions(&self, range: RevisionRange) -> Result<Revision, DocError> {
        debug_assert!(range.doc_id == self.doc_id);
        let revisions = self.rev_store.revs_in_range(range.clone()).await?;
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
        let revision = Revision::new(
            range.start,
            range.end,
            delta_data.to_vec(),
            &self.doc_id,
            RevType::Remote,
        );

        Ok(revision)
    }
}
