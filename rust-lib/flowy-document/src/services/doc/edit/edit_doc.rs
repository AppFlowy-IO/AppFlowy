use crate::{
    entities::{
        doc::{Doc, RevId, RevType, Revision, RevisionRange},
        ws::{WsDataType, WsDocumentData},
    },
    errors::{internal_error, DocError, DocResult},
    module::DocumentUser,
    services::{
        doc::{
            edit::{
                edit_actor::DocumentEditActor,
                message::{EditMsg, TransformDeltas},
                model::NotifyOpenDocAction,
            },
            revision::{DocRevision, RevisionCmd, RevisionManager, RevisionServer, RevisionStoreActor},
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
    document: UnboundedSender<EditMsg>,
    ws: Arc<dyn DocumentWebSocket>,
    pool: Arc<ConnectionPool>,
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
        let rev_store = spawn_rev_store_actor(doc_id, pool.clone(), server.clone());
        let DocRevision { rev_id, delta } = fetch_document(rev_store.clone()).await?;
        let rev_manager = Arc::new(RevisionManager::new(doc_id, rev_id, rev_store));
        let document = spawn_doc_edit_actor(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let edit_doc = Self {
            doc_id,
            rev_manager,
            document,
            pool,
            ws,
            user,
        };
        edit_doc.notify_open_doc();
        Ok(edit_doc)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let rev_id = self.mk_revision(&delta_data).await?;
        save_document(self.document.clone(), rev_id.into()).await
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Delete { interval, ret };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: Attribute) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<Delta>>();
        let msg = EditMsg::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.document.send(msg);
        let delta_data = rx.await.map_err(internal_error)??.to_bytes();
        let _ = self.mk_revision(&delta_data).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditMsg::CanUndo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditMsg::CanRedo { ret };
        let _ = self.document.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = EditMsg::Undo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn redo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocResult<UndoResult>>();
        let msg = EditMsg::Redo { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    pub async fn doc(&self) -> DocResult<Doc> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = EditMsg::Doc { ret };
        let _ = self.document.send(msg);
        let data = rx.await.map_err(internal_error)??;
        let rev_id = self.rev_manager.rev_id();
        let id = self.doc_id.clone();

        Ok(Doc { id, data, rev_id })
    }

    async fn mk_revision(&self, delta_data: &Bytes) -> Result<RevId, DocError> {
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let delta_data = delta_data.to_vec();
        let revision = Revision::new(base_rev_id, rev_id, delta_data, &self.doc_id, RevType::Local);
        let _ = self.rev_manager.add_revision(&revision).await?;
        match self.ws.send(revision.into()) {
            Ok(_) => {},
            Err(e) => log::error!("Send delta failed: {:?}", e),
        };

        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<DocResult<()>>();
        let msg = EditMsg::Delta { delta, ret };
        let _ = self.document.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        let rev_id = self.mk_revision(&data).await?;
        save_document(self.document.clone(), rev_id).await
    }

    #[cfg(feature = "flowy_test")]
    pub async fn doc_json(&self) -> DocResult<String> {
        let (ret, rx) = oneshot::channel::<DocResult<String>>();
        let msg = EditMsg::Doc { ret };
        let _ = self.document.send(msg);
        rx.await.map_err(internal_error)?
    }

    #[tracing::instrument(level = "debug", skip(self))]
    fn notify_open_doc(&self) {
        let rev_id: RevId = self.rev_manager.rev_id().into();

        if let Ok(user_id) = self.user.user_id() {
            let action = NotifyOpenDocAction::new(&user_id, &self.doc_id, &rev_id, &self.ws);
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
        let _ = self.document.send(EditMsg::RemoteRevision { bytes, ret });
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
        let msg = EditMsg::Delta {
            delta: client_prime.clone(),
            ret,
        };
        let _ = self.document.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        // update rev id
        self.rev_manager.update_rev_id(server_rev_id.clone().into());
        let (_, local_rev_id) = self.rev_manager.next_rev_id();

        // save the revision
        let revision = Revision::new(
            server_rev_id.value,
            local_rev_id,
            client_prime.to_bytes().to_vec(),
            &self.doc_id,
            RevType::Remote,
        );
        let _ = self.rev_manager.add_revision(&revision).await?;

        // send the server_prime delta
        let revision = Revision::new(
            server_rev_id.value,
            local_rev_id,
            server_prime.to_bytes().to_vec(),
            &self.doc_id,
            RevType::Remote,
        );
        self.ws.send(revision.into());

        save_document(self.document.clone(), local_rev_id.into()).await;
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
                let revision = self.rev_manager.send_revisions(range).await?;
                self.ws.send(revision.into());
            },
            WsDataType::NewDocUser => {},
            WsDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.rev_manager.ack_rev(rev_id);
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
            WsState::Connected(_) => {
                log::debug!("ws state changed: {}", state);
                self.0.notify_open_doc()
            },
            WsState::Disconnected(_) => {},
        }
    }
}

async fn save_document(document: UnboundedSender<EditMsg>, rev_id: RevId) -> DocResult<()> {
    let (ret, rx) = oneshot::channel::<DocResult<()>>();
    let _ = document.send(EditMsg::SaveDocument { rev_id, ret });
    let result = rx.await.map_err(internal_error)?;
    result
}

fn spawn_rev_store_actor(
    doc_id: &str,
    pool: Arc<ConnectionPool>,
    server: Arc<dyn RevisionServer>,
) -> mpsc::Sender<RevisionCmd> {
    let (sender, receiver) = mpsc::channel::<RevisionCmd>(50);
    let actor = RevisionStoreActor::new(doc_id, pool, receiver, server);
    tokio::spawn(actor.run());
    sender
}

fn spawn_doc_edit_actor(doc_id: &str, delta: Delta, pool: Arc<ConnectionPool>) -> UnboundedSender<EditMsg> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditMsg>();
    let actor = DocumentEditActor::new(&doc_id, delta, pool.clone(), receiver);
    tokio::spawn(actor.run());
    sender
}

async fn fetch_document(sender: mpsc::Sender<RevisionCmd>) -> DocResult<DocRevision> {
    let (ret, rx) = oneshot::channel();
    let _ = sender.send(RevisionCmd::DocumentDelta { ret }).await;

    match rx.await {
        Ok(result) => Ok(result?),
        Err(e) => {
            log::error!("fetch_document: {}", e);
            Err(DocError::internal().context(format!("fetch_document: {}", e)))
        },
    }
}
