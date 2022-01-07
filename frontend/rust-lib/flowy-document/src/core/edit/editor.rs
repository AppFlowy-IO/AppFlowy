use crate::{
    context::DocumentUser,
    core::{
        web_socket::{make_document_ws_manager, DocumentWebSocketManager},
        *,
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
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot};

pub struct ClientDocumentEditor {
    pub doc_id: String,
    rev_manager: Arc<DocumentRevisionManager>,
    ws_manager: Arc<dyn DocumentWebSocketManager>,
    edit_queue: UnboundedSender<EditorCommand>,
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

        let edit_queue = spawn_edit_queue(user, rev_manager.clone(), delta);
        let ws_manager = make_document_ws_manager(
            doc_id.clone(),
            user_id.clone(),
            edit_queue.clone(),
            rev_manager.clone(),
            ws,
        )
        .await;
        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            ws_manager,
            edit_queue,
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
        let _ = self.edit_queue.send(msg);
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<()>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.edit_queue.send(msg);
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
        let _ = self.edit_queue.send(msg);
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
        let _ = self.edit_queue.send(msg);
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanUndo { ret };
        let _ = self.edit_queue.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanRedo { ret };
        let _ = self.edit_queue.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Undo { ret };
        let _ = self.edit_queue.send(msg);
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn redo(&self) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel();
        let msg = EditorCommand::Redo { ret };
        let _ = self.edit_queue.send(msg);
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    pub async fn document_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<String>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.edit_queue.send(msg);
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
        let _ = self.edit_queue.send(msg);
        let _ = rx.await.map_err(internal_error)??;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub fn stop(&self) { self.ws_manager.stop(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWSReceiver> { self.ws_manager.receiver() }
}

fn spawn_edit_queue(
    user: Arc<dyn DocumentUser>,
    rev_manager: Arc<DocumentRevisionManager>,
    delta: RichTextDelta,
) -> UnboundedSender<EditorCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditorCommand>();
    let actor = EditorCommandQueue::new(user, rev_manager, delta, receiver);
    tokio::spawn(actor.run());
    sender
}

#[cfg(feature = "flowy_unit_test")]
impl ClientDocumentEditor {
    pub async fn doc_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.edit_queue.send(msg);
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
    }

    pub async fn doc_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditorCommand::ReadDocDelta { ret };
        let _ = self.edit_queue.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<DocumentRevisionManager> { self.rev_manager.clone() }
}
