use crate::{
    entities::doc::{RevId, RevType, Revision, RevisionRange},
    errors::{DocError, DocResult},
    services::{
        doc::revision::{
            actor::{RevisionCmd, RevisionStoreActor},
            util::NotifyOpenDocAction,
        },
        util::RevIdCounter,
        ws::WsDocumentSender,
    },
};
use flowy_infra::{
    future::ResultFuture,
    retry::{ExponentialBackoff, Retry},
};
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{collections::VecDeque, sync::Arc};
use tokio::sync::{mpsc, oneshot};

pub struct DocRevision {
    pub rev_id: RevId,
    pub delta: Delta,
}

pub trait RevisionServer: Send + Sync {
    fn fetch_document_from_remote(&self, doc_id: &str) -> ResultFuture<DocRevision, DocError>;
}

pub struct RevisionManager {
    doc_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    ws: Arc<dyn WsDocumentSender>,
    rev_store: mpsc::Sender<RevisionCmd>,
    pending_revs: RwLock<VecDeque<Revision>>,
}

impl RevisionManager {
    pub fn new(
        doc_id: &str,
        user_id: &str,
        rev_id: RevId,
        ws: Arc<dyn WsDocumentSender>,
        rev_store: mpsc::Sender<RevisionCmd>,
    ) -> Self {
        notify_open_doc(&ws, user_id, doc_id, &rev_id);

        let rev_id_counter = RevIdCounter::new(rev_id.into());
        let pending_revs = RwLock::new(VecDeque::new());
        Self {
            doc_id: doc_id.to_string(),
            user_id: user_id.to_string(),
            rev_id_counter,
            ws,
            pending_revs,
            rev_store,
        }
    }

    pub fn push_compose_revision(&self, revision: Revision) { self.pending_revs.write().push_front(revision); }

    pub fn next_compose_revision(&self) -> Option<Revision> { self.pending_revs.write().pop_front() }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn add_revision(&self, revision: Revision) -> Result<(), DocError> {
        let cmd = RevisionCmd::Revision {
            revision: revision.clone(),
        };
        let _ = self.rev_store.send(cmd).await;

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

    pub fn ack_rev(&self, rev_id: RevId) -> Result<(), DocError> {
        let sender = self.rev_store.clone();
        tokio::spawn(async move {
            let _ = sender.send(RevisionCmd::AckRevision { rev_id }).await;
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
        let sender = self.rev_store.clone();

        tokio::spawn(async move {
            let _ = sender.send(RevisionCmd::SendRevisions { range, ret }).await;
        });

        unimplemented!()
    }
}

// FIXME:
// user_id may be invalid if the user switch to another account while
// theNotifyOpenDocAction is flying
fn notify_open_doc(ws: &Arc<dyn WsDocumentSender>, user_id: &str, doc_id: &str, rev_id: &RevId) {
    let action = NotifyOpenDocAction::new(user_id, doc_id, rev_id, ws);
    let strategy = ExponentialBackoff::from_millis(50).take(3);
    let retry = Retry::spawn(strategy, action);
    tokio::spawn(async move {
        match retry.await {
            Ok(_) => {},
            Err(e) => log::error!("Notify open doc failed: {}", e),
        }
    });
}
