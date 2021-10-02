use crate::{
    entities::doc::{RevType, Revision, RevisionRange},
    errors::DocError,
    services::{
        doc::revision::store::{RevisionStore, StoreCmd},
        util::RevIdCounter,
        ws::WsDocumentSender,
    },
};

use crate::{entities::doc::Doc, errors::DocResult, services::server::Server};
use flowy_database::ConnectionPool;
use flowy_infra::future::ResultFuture;
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{mpsc, oneshot, oneshot::error::RecvError};

pub struct DocRevision {
    pub rev_id: i64,
    pub delta: Delta,
}

pub trait RevisionServer: Send + Sync {
    fn fetch_document_from_remote(&self, doc_id: &str) -> ResultFuture<DocRevision, DocError>;
}

pub struct RevisionManager {
    doc_id: String,
    rev_id_counter: RevIdCounter,
    ws: Arc<dyn WsDocumentSender>,
    store: mpsc::Sender<StoreCmd>,
    pending_revs: RwLock<VecDeque<Revision>>,
}

impl RevisionManager {
    pub async fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        ws_sender: Arc<dyn WsDocumentSender>,
        server: Arc<dyn RevisionServer>,
    ) -> DocResult<(Self, Delta)> {
        let (sender, receiver) = mpsc::channel::<StoreCmd>(50);
        let store = RevisionStore::new(doc_id, pool, receiver, server);
        tokio::spawn(store.run());

        let DocRevision { rev_id, delta } = fetch_document(sender.clone()).await?;

        let doc_id = doc_id.to_string();
        let rev_id_counter = RevIdCounter::new(rev_id);
        let pending_revs = RwLock::new(VecDeque::new());
        let manager = Self {
            doc_id,
            rev_id_counter,
            ws: ws_sender,
            pending_revs,
            store: sender,
        };
        Ok((manager, delta))
    }

    pub fn push_compose_revision(&self, revision: Revision) { self.pending_revs.write().push_front(revision); }

    pub fn next_compose_revision(&self) -> Option<Revision> { self.pending_revs.write().pop_front() }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn add_revision(&self, revision: Revision) -> Result<(), DocError> {
        let cmd = StoreCmd::Revision {
            revision: revision.clone(),
        };
        let _ = self.store.send(cmd).await;

        match revision.ty {
            RevType::Local => match self.ws.send(revision.into()) {
                Ok(_) => {},
                Err(e) => log::error!("Send delta failed: {:?}", e),
            },
            RevType::Remote => {
                self.pending_revs.write().push_back(revision);
            },
        }

        Ok(())
    }

    pub fn ack_rev(&self, rev_id: i64) -> Result<(), DocError> {
        let sender = self.store.clone();
        tokio::spawn(async move {
            let _ = sender.send(StoreCmd::AckRevision { rev_id }).await;
        });
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn send_revisions(&self, range: RevisionRange) -> Result<(), DocError> {
        debug_assert!(&range.doc_id == &self.doc_id);
        let (ret, _rx) = oneshot::channel();
        let sender = self.store.clone();

        tokio::spawn(async move {
            let _ = sender.send(StoreCmd::SendRevisions { range, ret }).await;
        });

        unimplemented!()
    }
}

async fn fetch_document(sender: mpsc::Sender<StoreCmd>) -> DocResult<DocRevision> {
    let (ret, rx) = oneshot::channel();
    let _ = sender.send(StoreCmd::DocumentDelta { ret }).await;

    match rx.await {
        Ok(result) => Ok(result?),
        Err(e) => {
            log::error!("fetch_document: {}", e);
            Err(DocError::internal().context(format!("fetch_document: {}", e)))
        },
    }
}
