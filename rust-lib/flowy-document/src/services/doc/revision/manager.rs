use crate::{
    entities::doc::{RevId, RevType, Revision, RevisionRange},
    errors::{internal_error, DocError},
    services::{
        doc::revision::{
            store_actor::{RevisionCmd, RevisionStoreActor},
            util::NotifyOpenDocAction,
        },
        util::RevIdCounter,
        ws::DocumentWebSocket,
    },
};
use flowy_infra::{
    future::ResultFuture,
    retry::{ExponentialBackoff, Retry},
};
use flowy_ot::core::Delta;
use flowy_ws::WsState;
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
    ws: Arc<dyn DocumentWebSocket>,
    rev_store: mpsc::Sender<RevisionCmd>,
}

impl RevisionManager {
    pub fn new(
        doc_id: &str,
        user_id: &str,
        rev_id: RevId,
        ws: Arc<dyn DocumentWebSocket>,
        rev_store: mpsc::Sender<RevisionCmd>,
    ) -> Self {
        notify_open_doc(&ws, user_id, doc_id, &rev_id);
        let rev_id_counter = RevIdCounter::new(rev_id.into());
        Self {
            doc_id: doc_id.to_string(),
            user_id: user_id.to_string(),
            rev_id_counter,
            ws,
            rev_store,
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn add_revision(&self, revision: Revision) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel();
        let cmd = RevisionCmd::Revision {
            revision: revision.clone(),
            ret,
        };
        let _ = self.rev_store.send(cmd).await;
        let result = rx.await.map_err(internal_error)?;
        if result.is_ok() && revision.ty.is_local() {
            match self.ws.send(revision.into()) {
                Ok(_) => {},
                Err(e) => log::error!("Send delta failed: {:?}", e),
            };
        }

        result
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

    pub async fn send_revisions(&self, range: RevisionRange) -> Result<(), DocError> {
        debug_assert!(&range.doc_id == &self.doc_id);
        let (ret, rx) = oneshot::channel();
        let sender = self.rev_store.clone();
        let _ = sender.send(RevisionCmd::SendRevisions { range, ret }).await;
        let revisions = rx.await.map_err(internal_error)??;

        unimplemented!()
        // Ok(())
    }

    #[tracing::instrument(
        level = "debug",
        skip(self),
        fields(
            doc_id = %self.doc_id.clone(),
            rev_id = %self.rev_id(),
        )
    )]
    pub fn handle_ws_state_changed(&self, state: &WsState) {
        match state {
            WsState::Init => {},
            WsState::Connected(_) => {
                let rev_id: RevId = self.rev_id().into();
                notify_open_doc(&self.ws, &self.user_id, &self.doc_id, &rev_id);
            },
            WsState::Disconnected(_) => {},
        }
    }
}

// FIXME:
// user_id may be invalid if the user switch to another account while
// theNotifyOpenDocAction is flying
fn notify_open_doc(ws: &Arc<dyn DocumentWebSocket>, user_id: &str, doc_id: &str, rev_id: &RevId) {
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
