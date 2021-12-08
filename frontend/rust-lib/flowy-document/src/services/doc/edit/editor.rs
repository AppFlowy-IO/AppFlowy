use crate::{
    errors::{internal_error, DocError, DocResult},
    module::DocumentUser,
    services::{
        doc::{
            edit::{EditCommand, EditCommandQueue, OpenDocAction, TransformDeltas},
            revision::{RevisionManager, RevisionServer},
        },
        ws::{DocumentWebSocket, WsDocumentHandler},
    },
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_document_infra::{
    core::history::UndoResult,
    entities::{
        doc::DocDelta,
        ws::{WsDataType, WsDocumentData},
    },
    errors::DocumentResult,
};
use lib_infra::retry::{ExponentialBackoff, Retry};
use lib_ot::{
    core::Interval,
    revision::{RevId, RevType, Revision, RevisionRange},
    rich_text::{RichTextAttribute, RichTextDelta},
};
use lib_ws::WsConnectState;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot};

pub type DocId = String;

pub struct ClientDocEditor {
    pub doc_id: DocId,
    rev_manager: Arc<RevisionManager>,
    edit_tx: UnboundedSender<EditCommand>,
    ws: Arc<dyn DocumentWebSocket>,
    user: Arc<dyn DocumentUser>,
}

impl ClientDocEditor {
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
        let edit_queue_tx = spawn_edit_queue(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let rev_manager = Arc::new(rev_manager);
        let edit_doc = Self {
            doc_id,
            rev_manager,
            edit_tx: edit_queue_tx,
            ws,
            user,
        };
        edit_doc.notify_open_doc();
        Ok(edit_doc)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<RichTextDelta>>();
        let msg = EditCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_tx.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta).await?;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<RichTextDelta>>();
        let msg = EditCommand::Delete { interval, ret };
        let _ = self.edit_tx.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<RichTextDelta>>();
        let msg = EditCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.edit_tx.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<(), DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<RichTextDelta>>();
        let msg = EditCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_tx.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditCommand::CanUndo { ret };
        let _ = self.edit_tx.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditCommand::CanRedo { ret };
        let _ = self.edit_tx.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<UndoResult>>();
        let msg = EditCommand::Undo { ret };
        let _ = self.edit_tx.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn redo(&self) -> Result<UndoResult, DocError> {
        let (ret, rx) = oneshot::channel::<DocumentResult<UndoResult>>();
        let msg = EditCommand::Redo { ret };
        let _ = self.edit_tx.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn delta(&self) -> DocResult<DocDelta> {
        let (ret, rx) = oneshot::channel::<DocumentResult<String>>();
        let msg = EditCommand::ReadDoc { ret };
        let _ = self.edit_tx.send(msg);
        let data = rx.await.map_err(internal_error)??;

        Ok(DocDelta {
            doc_id: self.doc_id.clone(),
            data,
        })
    }

    async fn save_local_delta(&self, delta: RichTextDelta) -> Result<RevId, DocError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let delta_data = delta_data.to_vec();
        let revision = Revision::new(base_rev_id, rev_id, delta_data, &self.doc_id, RevType::Local);
        let _ = self.rev_manager.add_revision(&revision).await?;
        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn composing_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<DocumentResult<()>>();
        let msg = EditCommand::ComposeDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.edit_tx.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        let _ = self.save_local_delta(delta).await?;
        Ok(())
    }

    #[cfg(feature = "flowy_test")]
    pub async fn doc_json(&self) -> DocResult<String> {
        let (ret, rx) = oneshot::channel::<DocumentResult<String>>();
        let msg = EditCommand::ReadDoc { ret };
        let _ = self.edit_tx.send(msg);
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
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
                    Ok(_) => log::debug!("Notify open doc success"),
                    Err(e) => log::error!("Notify open doc failed: {}", e),
                }
            });
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    async fn handle_push_rev(&self, bytes: Bytes) -> DocResult<()> {
        // Transform the revision
        let (ret, rx) = oneshot::channel::<DocumentResult<TransformDeltas>>();
        let _ = self.edit_tx.send(EditCommand::RemoteRevision { bytes, ret });
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
        let (ret, rx) = oneshot::channel::<DocumentResult<()>>();
        let msg = EditCommand::ComposeDelta {
            delta: client_prime.clone(),
            ret,
        };
        let _ = self.edit_tx.send(msg);
        let _ = rx.await.map_err(internal_error)??;

        // update rev id
        self.rev_manager
            .update_rev_id_counter_value(server_rev_id.clone().into());
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
                let revision = self.rev_manager.mk_revisions(range).await?;
                let _ = self.ws.send(revision.into());
            },
            WsDataType::NewDocUser => {},
            WsDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.rev_manager.ack_revision(rev_id).await?;
            },
            WsDataType::Conflict => {},
        }
        Ok(())
    }
}

pub struct EditDocWsHandler(pub Arc<ClientDocEditor>);

impl std::ops::Deref for EditDocWsHandler {
    type Target = Arc<ClientDocEditor>;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl WsDocumentHandler for EditDocWsHandler {
    fn receive(&self, doc_data: WsDocumentData) {
        let edit_doc = self.0.clone();
        tokio::spawn(async move {
            if let Err(e) = edit_doc.handle_ws_message(doc_data).await {
                log::error!("{:?}", e);
            }
        });
    }

    fn state_changed(&self, state: &WsConnectState) {
        match state {
            WsConnectState::Init => {},
            WsConnectState::Connecting => {},
            WsConnectState::Connected => self.notify_open_doc(),
            WsConnectState::Disconnected => {},
        }
    }
}

fn spawn_rev_receiver(mut receiver: mpsc::UnboundedReceiver<Revision>, ws: Arc<dyn DocumentWebSocket>) {
    tokio::spawn(async move {
        loop {
            while let Some(revision) = receiver.recv().await {
                // tracing::debug!("Send revision:{} to server", revision.rev_id);
                match ws.send(revision.into()) {
                    Ok(_) => {},
                    Err(e) => log::error!("Send revision failed: {:?}", e),
                };
            }
        }
    });
}

fn spawn_edit_queue(doc_id: &str, delta: RichTextDelta, _pool: Arc<ConnectionPool>) -> UnboundedSender<EditCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditCommand>();
    let actor = EditCommandQueue::new(doc_id, delta, receiver);
    tokio::spawn(actor.run());
    sender
}
