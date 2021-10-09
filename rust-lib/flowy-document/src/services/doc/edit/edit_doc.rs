use crate::{
    entities::{
        doc::{DocDelta, RevId, RevType, Revision, RevisionRange},
        ws::{WsDataType, WsDocumentData},
    },
    errors::{internal_error, DocError, DocResult},
    module::DocumentUser,
    services::{
        doc::{
            edit::{
                doc_actor::DocumentActor,
                message::{DocumentMsg, TransformDeltas},
                model::OpenDocAction,
            },
            revision::{RevisionManager, RevisionServer},
            UndoResult,
        },
        ws::{DocumentWebSocket, WsDocumentHandler},
    },
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_infra::retry::{ExponentialBackoff, Retry};
use flowy_ot::core::{Attribute, Delta, Interval};
use flowy_ws::WsState;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot};

pub type DocId = String;

pub struct ClientEditDoc {
    pub doc_id: DocId,
    rev_manager: Arc<RevisionManager>,
    document: UnboundedSender<DocumentMsg>,
    ws: Arc<dyn DocumentWebSocket>,
    user: Arc<dyn DocumentUser>,
}

impl ClientEditDoc {
    pub(crate) async fn new(
        doc_id: &str,
        pool: Arc<ConnectionPool>,
        ws: Arc<dyn DocumentWebSocket>,
        server: Arc<dyn RevisionServer>,
        user: Arc<dyn DocumentUser>,
    ) -> DocResult<Self> {
        let (sender, receiver) = mpsc::unbounded_channel();
        let mut rev_manager = RevisionManager::new(doc_id, pool.clone(), server.clone(), sender);
        spawn_rev_receiver(receiver, ws.clone());

        let delta = rev_manager.load_document().await?;
        let document = spawn_doc_edit_actor(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let rev_manager = Arc::new(rev_manager);
        let edit_doc = Self {
            doc_id,
            rev_manager,
            document,
            ws,
            user,
        };
        edit_doc.notify_open_doc();
        Ok(edit_doc)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = DocumentMsg::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let rev_id = self.save_revision(delta).await?;
        save_document(self.document.clone(), rev_id.into()).await
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = DocumentMsg::Delete { interval, ret };
        let _ = self.document.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_revision(delta).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: Attribute) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = DocumentMsg::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.document.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_revision(delta).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = DocumentMsg::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_revision(delta).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = DocumentMsg::CanUndo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = DocumentMsg::CanRedo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = DocumentMsg::Undo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn redo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = DocumentMsg::Redo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn delta(&self) -> DocResult<DocDelta> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = DocumentMsg::Doc { ret };
        let _ = self.document.send(msg);
        let data = rx.await.map_err(internal_error)??;

        Ok(DocDelta {
            doc_id: self.doc_id.clone(),
            data,
        })
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(revision_delta = %delta.to_json(), send_state, base_rev_id, rev_id))]
    async fn save_revision(&self, delta: Delta) -> Result<RevId, DocError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        tracing::Span::current().record("base_rev_id", &base_rev_id);
        tracing::Span::current().record("rev_id", &rev_id);

        let delta_data = delta_data.to_vec();
        let revision = Revision::new(base_rev_id, rev_id, delta_data, &self.doc_id, RevType::Local);
        let _ = self.rev_manager.add_revision(&revision).await?;
        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<DocResult<()>>();
        let msg = DocumentMsg::Delta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.document.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        let rev_id = self.save_revision(delta).await?;
        save_document(self.document.clone(), rev_id).await
    }

    #[cfg(feature = "flowy_test")]
    pub async fn doc_json(&self) -> DocResult<String> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = DocumentMsg::Doc { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    #[tracing::instrument(level = "debug", skip(self))]
    fn notify_open_doc(&self) {
        let rev_id: RevId = self.rev_manager.rev_id().into();

        if let Ok(user_id) = self.user.user_id() {
            let action = OpenDocAction::new(&user_id, &self.doc_id, &rev_id, &self.ws);
            let strategy = ExponentialBackoff::from_millis(50).take(3);
            let retry = Retry::spawn(strategy, action);
            tokio::spawn(async move {
                match retry.await {
                    Ok(_) => {},
                    Err(e) => log::error!("Notify open doc failed: {}", e),
                }
            });
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    async fn handle_push_rev(&self, bytes: Bytes) -> DocResult<()> {
        // Transform the revision
        let (ret, rx) = oneshot::channel::<DocResult<TransformDeltas>>();
        let _ = self.document.send(DocumentMsg::RemoteRevision { bytes, ret });
        let TransformDeltas {
            client_prime,
            server_prime,
            server_rev_id,
        } = rx.await.map_err(internal_error)??;

        if self.rev_manager.rev_id() >= server_rev_id.value {
            // Ignore this push revision if local_rev_id >= server_rev_id
            return Ok(());
        }

        // compose delta
        let (ret, rx) = oneshot::channel::<DocResult<()>>();
        let msg = DocumentMsg::Delta {
            delta: client_prime.clone(),
            ret,
        };
        let _ = self.document.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        // update rev id
        self.rev_manager.set_rev_id(server_rev_id.clone().into());
        let (local_base_rev_id, local_rev_id) = self.rev_manager.next_rev_id();

        // save the revision
        let revision = Revision::new(
            local_base_rev_id,
            local_rev_id,
            client_prime.to_bytes().to_vec(),
            &self.doc_id,
            RevType::Remote,
        );
        let _ = self.rev_manager.add_revision(&revision).await?;

        // send the server_prime delta
        let revision = Revision::new(
            local_base_rev_id,
            local_rev_id,
            server_prime.to_bytes().to_vec(),
            &self.doc_id,
            RevType::Remote,
        );
        let _ = self.ws.send(revision.into());

        let _ = save_document(self.document.clone(), local_rev_id.into()).await?;
        Ok(())
    }

    async fn handle_ws_message(&self, doc_data: WsDocumentData) -> DocResult<()> {
        let bytes = Bytes::from(doc_data.data);
        match doc_data.ty {
            WsDataType::PushRev => {
                let _ = self.handle_push_rev(bytes).await?;
            },
            WsDataType::PullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let revision = self.rev_manager.construct_revisions(range).await?;
                let _ = self.ws.send(revision.into());
            },
            WsDataType::NewDocUser => {},
            WsDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.rev_manager.ack_rev(rev_id).await?;
            },
            WsDataType::Conflict => {},
        }
        Ok(())
    }
}

pub struct EditDocWsHandler(pub Arc<ClientEditDoc>);

impl WsDocumentHandler for EditDocWsHandler {
    fn receive(&self, doc_data: WsDocumentData) {
        let edit_doc = self.0.clone();
        tokio::spawn(async move {
            if let Err(e) = edit_doc.handle_ws_message(doc_data).await {
                log::error!("{:?}", e);
            }
        });
    }

    fn state_changed(&self, state: &WsState) {
        match state {
            WsState::Init => {},
            WsState::Connected(_) => self.0.notify_open_doc(),
            WsState::Disconnected(_e) => {},
        }
    }
}

fn spawn_rev_receiver(mut receiver: mpsc::UnboundedReceiver<Revision>, ws: Arc<dyn DocumentWebSocket>) {
    tokio::spawn(async move {
        loop {
            while let Some(revision) = receiver.recv().await {
                log::debug!("Send revision:{} to server", revision.rev_id);
                match ws.send(revision.into()) {
                    Ok(_) => {},
                    Err(e) => log::error!("Send revision failed: {:?}", e),
                };
            }
        }
    });
}

async fn save_document(document: UnboundedSender<DocumentMsg>, rev_id: RevId) -> DocResult<()> {
    let (ret, rx) = oneshot::channel::<DocResult<()>>();
    let _ = document.send(DocumentMsg::SaveDocument { rev_id, ret });
    let result = rx.await.map_err(internal_error)?;
    result
}

fn spawn_doc_edit_actor(_doc_id: &str, delta: Delta, _pool: Arc<ConnectionPool>) -> UnboundedSender<DocumentMsg> {
    let (sender, receiver) = mpsc::unbounded_channel::<DocumentMsg>();
    let actor = DocumentActor::new(delta, receiver);
    tokio::spawn(actor.run());
    sender
}
