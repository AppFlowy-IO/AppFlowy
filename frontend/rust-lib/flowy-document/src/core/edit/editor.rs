use crate::{
    context::DocumentUser,
    core::{
        web_socket::{make_document_ws_manager, DocumentWebSocketManager, EditorCommandSender},
        DocumentRevisionManager,
        DocumentWSReceiver,
        DocumentWebSocket,
        EditorCommand,
        EditorCommandQueue,
        RevisionServer,
    },
    errors::FlowyError,
};
use bytes::Bytes;
use flowy_collaboration::errors::CollaborateResult;
use flowy_error::{internal_error, FlowyResult};
use lib_ot::{
    core::Interval,
    rich_text::{RichTextAttribute, RichTextDelta},
};
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub struct ClientDocumentEditor {
    pub doc_id: String,
    #[allow(dead_code)]
    rev_manager: Arc<DocumentRevisionManager>,
    ws_manager: Arc<DocumentWebSocketManager>,
    edit_cmd_tx: EditorCommandSender,
}

impl ClientDocumentEditor {
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        mut rev_manager: DocumentRevisionManager,
        ws: Arc<dyn DocumentWebSocket>,
        server: Arc<dyn RevisionServer>,
    ) -> FlowyResult<Arc<Self>> {
        let delta = rev_manager.load_document(server).await?;
        let rev_manager = Arc::new(rev_manager);
        let doc_id = doc_id.to_string();
        let user_id = user.user_id()?;

        let edit_cmd_tx = spawn_edit_queue(user, rev_manager.clone(), delta);
        let ws_manager = make_document_ws_manager(
            doc_id.clone(),
            user_id.clone(),
            edit_cmd_tx.clone(),
            rev_manager.clone(),
            ws,
        )
        .await;
        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            ws_manager,
            edit_cmd_tx,
        });
        Ok(editor)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn replace<T: ToString>(&self, interval: Interval, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanUndo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanRedo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Undo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn redo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Redo { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn document_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<String>>();
        let msg = EditorCommand::ReadDocumentAsJson { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let json = rx.await.map_err(internal_error)??;
        Ok(json)
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), FlowyError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::ComposeLocalDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.edit_cmd_tx.send(msg).await;
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub fn stop(&self) { self.ws_manager.stop(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWSReceiver> { self.ws_manager.clone() }
}

impl std::ops::Drop for ClientDocumentEditor {
    fn drop(&mut self) { tracing::trace!("{} ClientDocumentEditor was dropped", self.doc_id) }
}

// The edit queue will exit after the EditorCommandSender was dropped.
fn spawn_edit_queue(
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<DocumentRevisionManager>,
    delta: RichTextDelta,
) -> EditorCommandSender {
    let (sender, receiver) = mpsc::channel(1000);
    let actor = EditorCommandQueue::new(user, rev_manager, delta, receiver);
    tokio::spawn(actor.run());
    sender
}

#[cfg(feature = "flowy_unit_test")]
impl ClientDocumentEditor {
    pub async fn doc_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<crate::core::DocumentMD5>>();
        let msg = EditorCommand::ReadDocumentAsJson { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
    }

    pub async fn doc_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditorCommand::ReadDocumentAsDelta { ret };
        let _ = self.edit_cmd_tx.send(msg).await;
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<DocumentRevisionManager> { self.rev_manager.clone() }
}
