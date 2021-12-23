use crate::{
    errors::FlowyError,
    module::DocumentUser,
    services::doc::{
        web_socket::{initialize_document_web_socket, DocumentWebSocketContext, EditorWebSocket},
        *,
    },
};
use bytes::Bytes;
use flowy_collaboration::{
    core::document::history::UndoResult,
    entities::{
        doc::DocumentDelta,
        revision::{RevId, RevType, Revision},
    },
    errors::CollaborateResult,
};
use flowy_database::ConnectionPool;
use flowy_error::{internal_error, FlowyResult};
use lib_ot::{
    core::Interval,
    rich_text::{RichTextAttribute, RichTextDelta},
};
use std::sync::Arc;
use tokio::sync::{mpsc, mpsc::UnboundedSender, oneshot};

pub struct ClientDocEditor {
    pub doc_id: String,
    rev_manager: Arc<RevisionManager>,
    editor_ws: Arc<dyn EditorWebSocket>,
    editor_cmd_sender: UnboundedSender<EditorCommand>,
    user: Arc<dyn DocumentUser>,
}

impl ClientDocEditor {
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        pool: Arc<ConnectionPool>,
        mut rev_manager: RevisionManager,
        ws: Arc<dyn DocumentWebSocket>,
        server: Arc<dyn RevisionServer>,
    ) -> FlowyResult<Arc<Self>> {
        let delta = rev_manager.load_document(server).await?;
        let editor_cmd_sender = spawn_edit_queue(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let user_id = user.user_id()?;
        let rev_manager = Arc::new(rev_manager);

        let context = DocumentWebSocketContext {
            doc_id: doc_id.to_owned(),
            user_id: user_id.clone(),
            editor_cmd_sender: editor_cmd_sender.clone(),
            rev_manager: rev_manager.clone(),
            ws,
        };

        let editor_ws = initialize_document_web_socket(context).await;
        let editor = Arc::new(Self {
            doc_id,
            rev_manager,
            editor_ws,
            editor_cmd_sender,
            user,
        });
        Ok(editor)
    }

    pub async fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Insert {
            index,
            data: data.to_string(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn format(&self, interval: Interval, attribute: RichTextAttribute) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Format {
            interval,
            attribute,
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn replace<T: ToString>(&self, interval: Interval, data: T) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Replace {
            interval,
            data: data.to_string(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn can_undo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanUndo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn can_redo(&self) -> bool {
        let (ret, rx) = oneshot::channel::<bool>();
        let msg = EditorCommand::CanRedo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        rx.await.unwrap_or(false)
    }

    pub async fn undo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Undo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn redo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Redo { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn delta(&self) -> FlowyResult<DocumentDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let data = rx.await.map_err(internal_error)??;

        Ok(DocumentDelta {
            doc_id: self.doc_id.clone(),
            text: data,
        })
    }

    async fn save_local_delta(&self, delta: RichTextDelta, md5: String) -> Result<RevId, FlowyError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(
            &self.doc_id,
            base_rev_id,
            rev_id,
            delta_data,
            RevType::Local,
            &user_id,
            md5,
        );
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn composing_local_delta(&self, data: Bytes) -> Result<(), FlowyError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ComposeDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.editor_cmd_sender.send(msg);
        let md5 = rx.await.map_err(internal_error)??;

        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub fn stop(&self) { self.editor_ws.stop_web_socket(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWsHandler> { self.editor_ws.ws_handler() }
}

fn spawn_edit_queue(doc_id: &str, delta: RichTextDelta, _pool: Arc<ConnectionPool>) -> UnboundedSender<EditorCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditorCommand>();
    let actor = EditorCommandQueue::new(doc_id, delta, receiver);
    tokio::spawn(actor.run());
    sender
}

#[cfg(feature = "flowy_unit_test")]
impl ClientDocEditor {
    pub async fn doc_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let s = rx.await.map_err(internal_error)??;
        Ok(s)
    }

    pub async fn doc_delta(&self) -> FlowyResult<RichTextDelta> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<RichTextDelta>>();
        let msg = EditorCommand::ReadDocDelta { ret };
        let _ = self.editor_cmd_sender.send(msg);
        let delta = rx.await.map_err(internal_error)??;
        Ok(delta)
    }

    pub fn rev_manager(&self) -> Arc<RevisionManager> { self.rev_manager.clone() }
}
