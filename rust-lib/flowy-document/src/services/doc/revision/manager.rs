use crate::{
    entities::doc::{Doc, RevId, RevType, Revision, RevisionRange},
    errors::{DocError, DocResult},
    services::{doc::revision::RevisionStore, util::RevIdCounter},
};
use flowy_database::ConnectionPool;
use flowy_infra::future::ResultFuture;
use flowy_ot::core::{Delta, OperationTransformable};
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

    pub async fn load_document(&mut self) -> DocResult<Delta> {
        let doc = self.rev_store.fetch_document().await?;
        self.set_rev_id(doc.rev_id);
        Ok(doc.delta()?)
    }

    pub async fn add_revision(&self, revision: &Revision) -> Result<(), DocError> {
        let _ = self.rev_store.handle_new_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn ack_rev(&self, rev_id: RevId) -> Result<(), DocError> {
        self.rev_store.handle_revision_acked(rev_id).await;
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn set_rev_id(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub async fn mk_revisions(&self, range: RevisionRange) -> Result<Revision, DocError> {
        debug_assert!(&range.doc_id == &self.doc_id);
        let revisions = self.rev_store.revs_in_range(range.clone()).await?;
        let mut new_delta = Delta::new();
        for revision in revisions {
            match Delta::from_bytes(revision.delta_data) {
                Ok(delta) => {
                    new_delta = new_delta.compose(&delta)?;
                },
                Err(_) => {},
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
