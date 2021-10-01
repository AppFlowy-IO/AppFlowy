use crate::{
    entities::doc::{RevType, Revision, RevisionRange},
    errors::DocError,
    services::{
        doc::rev_manager::store::{Store, StoreMsg},
        util::RevIdCounter,
        ws::WsDocumentSender,
    },
};

use flowy_database::ConnectionPool;
use parking_lot::RwLock;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{mpsc, oneshot};

pub struct RevisionManager {
    doc_id: String,
    rev_id_counter: RevIdCounter,
    ws_sender: Arc<dyn WsDocumentSender>,
    store_sender: mpsc::Sender<StoreMsg>,
    pending_revs: RwLock<VecDeque<Revision>>,
}
// tokio::time::timeout
impl RevisionManager {
    pub fn new(doc_id: &str, rev_id: i64, pool: Arc<ConnectionPool>, ws_sender: Arc<dyn WsDocumentSender>) -> Self {
        let (sender, receiver) = mpsc::channel::<StoreMsg>(50);
        let store = Store::new(doc_id, pool, receiver);
        tokio::spawn(store.run());

        let doc_id = doc_id.to_string();
        let rev_id_counter = RevIdCounter::new(rev_id);
        let pending_revs = RwLock::new(VecDeque::new());
        Self {
            doc_id,
            rev_id_counter,
            ws_sender,
            pending_revs,
            store_sender: sender,
        }
    }

    pub fn push_compose_revision(&self, revision: Revision) { self.pending_revs.write().push_front(revision); }

    pub fn next_compose_revision(&self) -> Option<Revision> { self.pending_revs.write().pop_front() }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub async fn add_revision(&self, revision: Revision) -> Result<(), DocError> {
        let msg = StoreMsg::Revision {
            revision: revision.clone(),
        };
        let _ = self.store_sender.send(msg).await;

        match revision.ty {
            RevType::Local => match self.ws_sender.send(revision.into()) {
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
        let sender = self.store_sender.clone();
        tokio::spawn(async move {
            let _ = sender.send(StoreMsg::AckRevision { rev_id }).await;
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
        let sender = self.store_sender.clone();

        tokio::spawn(async move {
            let _ = sender.send(StoreMsg::SendRevisions { range, ret }).await;
        });

        unimplemented!()
    }
}
