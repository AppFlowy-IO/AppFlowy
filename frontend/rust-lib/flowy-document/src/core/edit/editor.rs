use crate::{
    context::DocumentUser,
<<<<<<< HEAD:frontend/rust-lib/flowy-document/src/core/edit/editor.rs
<<<<<<< HEAD:frontend/rust-lib/flowy-document/src/services/doc/edit/editor.rs
    errors::FlowyError,
    services::doc::{
=======
    core::{
>>>>>>> upstream/main:frontend/rust-lib/flowy-document/src/core/edit/editor.rs
=======
    core::{
>>>>>>> upstream/main:frontend/rust-lib/flowy-document/src/services/doc/edit/editor.rs
        web_socket::{make_document_ws_manager, DocumentWebSocketManager},
        *,
    },
    errors::FlowyError,
};
use bytes::Bytes;
use flowy_collaboration::{
    document::history::UndoResult,
    entities::revision::{RevId, Revision},
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

pub struct ClientDocumentEditor {
    pub doc_id: String,
    rev_manager: Arc<RevisionManager>,
    ws_manager: Arc<dyn DocumentWebSocketManager>,
    edit_queue: UnboundedSender<EditorCommand>,
    user: Arc<dyn DocumentUser>,
}

impl ClientDocumentEditor {
    pub(crate) async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        pool: Arc<ConnectionPool>,
        mut rev_manager: RevisionManager,
        ws: Arc<dyn DocumentWebSocket>,
        server: Arc<dyn RevisionServer>,
    ) -> FlowyResult<Arc<Self>> {
        let delta = rev_manager.load_document(server).await?;
        let edit_queue = spawn_edit_queue(doc_id, delta, pool.clone());
        let doc_id = doc_id.to_string();
        let user_id = user.user_id()?;
        let rev_manager = Arc::new(rev_manager);

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
        let _ = self.edit_queue.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    pub async fn delete(&self, interval: Interval) -> Result<(), FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<NewDelta>>();
        let msg = EditorCommand::Delete { interval, ret };
        let _ = self.edit_queue.send(msg);
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
        let _ = self.edit_queue.send(msg);
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
        let _ = self.edit_queue.send(msg);
        let (delta, md5) = rx.await.map_err(internal_error)??;
        let _ = self.save_local_delta(delta, md5).await?;
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

    pub async fn undo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Undo { ret };
        let _ = self.edit_queue.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn redo(&self) -> Result<UndoResult, FlowyError> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<UndoResult>>();
        let msg = EditorCommand::Redo { ret };
        let _ = self.edit_queue.send(msg);
        let r = rx.await.map_err(internal_error)??;
        Ok(r)
    }

    pub async fn document_json(&self) -> FlowyResult<String> {
        let (ret, rx) = oneshot::channel::<CollaborateResult<String>>();
        let msg = EditorCommand::ReadDoc { ret };
        let _ = self.edit_queue.send(msg);
        let json = rx.await.map_err(internal_error)??;
        Ok(json)
    }

    async fn save_local_delta(&self, delta: RichTextDelta, md5: String) -> Result<RevId, FlowyError> {
        let delta_data = delta.to_bytes();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(&self.doc_id, base_rev_id, rev_id, delta_data, &user_id, md5);
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) async fn compose_local_delta(&self, data: Bytes) -> Result<(), FlowyError> {
        let delta = RichTextDelta::from_bytes(&data)?;
        let (ret, rx) = oneshot::channel::<CollaborateResult<DocumentMD5>>();
        let msg = EditorCommand::ComposeDelta {
            delta: delta.clone(),
            ret,
        };
        let _ = self.edit_queue.send(msg);
        let md5 = rx.await.map_err(internal_error)??;

        let _ = self.save_local_delta(delta, md5).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub fn stop(&self) { self.ws_manager.stop(); }

    pub(crate) fn ws_handler(&self) -> Arc<dyn DocumentWSReceiver> { self.ws_manager.receiver() }
}

fn spawn_edit_queue(doc_id: &str, delta: RichTextDelta, _pool: Arc<ConnectionPool>) -> UnboundedSender<EditorCommand> {
    let (sender, receiver) = mpsc::unbounded_channel::<EditorCommand>();
    let actor = EditorCommandQueue::new(doc_id, delta, receiver);
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

    pub fn rev_manager(&self) -> Arc<RevisionManager> { self.rev_manager.clone() }
}
